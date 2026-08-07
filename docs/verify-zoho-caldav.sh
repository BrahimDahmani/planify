#!/bin/bash
# Zoho CalDAV Verification Script
# This script helps verify that the Zoho CalDAV adapter implementation is working

echo "=== Zoho CalDAV Verification Script ==="
echo ""
echo "This script will help you test the Zoho CalDAV adapter."
echo ""

# Check for required environment variables
if [ -z "$ZOHO_CALDAV_URL" ] || [ -z "$ZOHO_CALDAV_USER" ] || [ -z "$ZOHO_CALDAV_PASS" ]; then
    echo "⚠️  Missing environment variables. Please set:"
    echo "   export ZOHO_CALDAV_URL='https://calendar.zoho.com/caldav/username/zohoTask_123/'"
    echo "   export ZOHO_CALDAV_USER='your-email@example.com'"
    echo "   export ZOHO_CALDAV_PASS='your-app-password'"
    echo ""
    echo "You can get these from:"
    echo "1. Zoho CalDAV URL: Check your Zoho Calendar settings"
    echo "2. Username: Your Zoho email address"
    echo "3. Password: Generate an app-specific password in Zoho Account Settings"
    echo ""
    exit 1
fi

echo "✓ Environment variables found"
echo ""

# Test 1: PROPFIND to check calendar properties
echo "Test 1: Checking calendar properties (PROPFIND)..."
echo "========================================"

PROPFIND_RESPONSE=$(curl -s -X PROPFIND "$ZOHO_CALDAV_URL" \
  -u "$ZOHO_CALDAV_USER:$ZOHO_CALDAV_PASS" \
  -H 'Content-Type: application/xml' \
  -H 'Depth: 0' \
  -d '<?xml version="1.0" encoding="utf-8"?>
<d:propfind xmlns:d="DAV:" xmlns:cal="urn:ietf:params:xml:ns:caldav">
  <d:prop>
    <d:resourcetype/>
    <d:displayname/>
    <cal:supported-calendar-component-set/>
  </d:prop>
</d:propfind>')

echo "$PROPFIND_RESPONSE"
echo ""

# Check if response contains supported-calendar-component-set
if echo "$PROPFIND_RESPONSE" | grep -q "supported-calendar-component-set"; then
    echo "✓ Found supported-calendar-component-set property"
    if echo "$PROPFIND_RESPONSE" | grep -q "VTODO"; then
        echo "✓ Calendar advertises VTODO support (standard CalDAV)"
        echo "  → Zoho adapter probe should not be triggered"
    else
        echo "⚠️  Calendar has supported-calendar-component-set but no VTODO"
        echo "  → Zoho adapter probe WILL be triggered"
    fi
else
    echo "⚠️  No supported-calendar-component-set found"
    echo "  → Zoho adapter probe WILL be triggered"
fi
echo ""

# Test 2: REPORT to probe for VTODO components
echo "Test 2: Probing for VTODO components (REPORT)..."
echo "========================================"

REPORT_RESPONSE=$(curl -s -X REPORT "$ZOHO_CALDAV_URL" \
  -u "$ZOHO_CALDAV_USER:$ZOHO_CALDAV_PASS" \
  -H 'Content-Type: application/xml' \
  -H 'Depth: 1' \
  -d '<?xml version="1.0" encoding="utf-8"?>
<cal:calendar-query xmlns:d="DAV:" xmlns:cal="urn:ietf:params:xml:ns:caldav">
  <d:prop>
    <d:getetag/>
    <cal:calendar-data/>
  </d:prop>
  <cal:filter>
    <cal:comp-filter name="VCALENDAR">
      <cal:comp-filter name="VTODO"/>
    </cal:comp-filter>
  </cal:filter>
</cal:calendar-query>')

echo "$REPORT_RESPONSE" | head -50
echo ""

# Check if response contains VTODO components
if echo "$REPORT_RESPONSE" | grep -q "VTODO"; then
    echo "✓ Found VTODO components!"
    echo "  → Zoho adapter should import this calendar as a task list"
    VTODO_COUNT=$(echo "$REPORT_RESPONSE" | grep -c "BEGIN:VTODO")
    echo "  → Found approximately $VTODO_COUNT tasks"
else
    echo "⚠️  No VTODO components found"
    echo "  → This may not be a task calendar"
fi
echo ""

# Summary
echo "=== Summary ==="
echo ""
echo "Expected behavior in Planify:"
if echo "$PROPFIND_RESPONSE" | grep -q "VTODO"; then
    echo "1. Standard CalDAV detection will work"
    echo "2. Zoho adapter probe will NOT be triggered"
else
    echo "1. Standard CalDAV detection will NOT detect this as a task calendar"
    echo "2. Zoho adapter probe WILL be triggered"
    if echo "$REPORT_RESPONSE" | grep -q "VTODO"; then
        echo "3. Probe will find VTODOs and import the calendar ✓"
    else
        echo "3. Probe will NOT find VTODOs and skip this calendar"
    fi
fi
echo ""
echo "To run the Planify tests:"
echo "  cd /home/runner/work/planify/planify/build"
echo "  meson test caldav-zoho"
