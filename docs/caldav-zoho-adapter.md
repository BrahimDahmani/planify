# Zoho CalDAV Adapter

## Overview

The Zoho CalDAV adapter is a specialized provider that handles Zoho Calendar's non-standard CalDAV implementation. Zoho's CalDAV server does not advertise VTODO support in the `supported-calendar-component-set` property, even though it does support task (VTODO) calendars.

## Why This Adapter Exists

Standard CalDAV servers advertise their supported calendar component types (VEVENT, VTODO, VJOURNAL) via the `cal:supported-calendar-component-set` property in PROPFIND responses. Planify uses this information to identify which calendars contain tasks (VTODO components).

However, Zoho Calendar does not include this property (or includes it without VTODO) for task calendars, making it impossible to distinguish task calendars from event calendars using standard discovery methods.

## How It Works

The adapter uses a two-phase approach:

### 1. Detection

The adapter identifies Zoho CalDAV endpoints by checking:
- **Domain matching**: Looks for `calendar.zoho.com`, `calendar.zoho.eu`, `calendar.zoho.in`, or `calendar.zoho.com.au`
- **URL patterns**: Checks for Zoho-specific patterns like `zohoTask_` in the URL path

### 2. Probing

When a calendar doesn't advertise VTODO support but is identified as a Zoho endpoint, the adapter:

1. Sends a CalDAV REPORT query specifically for VTODO components
2. Checks if any VTODO items are returned
3. Returns one of three results:
   - `VTODO_FOUND`: The calendar contains tasks and should be imported
   - `VEVENT_ONLY`: The calendar only contains events (not imported as a task list)
   - `NONE`: The calendar is empty or inaccessible

## Integration

The adapter is integrated into the CalDAV client's discovery flow:

1. During `fetch_project_list()` and `sync()`, after checking the standard `is_vtodo_calendar()` method
2. If a calendar is not identified as a VTODO calendar AND it's a Zoho endpoint
3. The adapter's `probe_calendar()` method is called
4. If VTODOs are found, the calendar is imported as a project

## Limitations

- **Read-only by default**: The initial implementation focuses on importing and reading tasks from Zoho
- **Probing overhead**: Each Zoho calendar requires an additional REPORT query during discovery
- **Best-effort detection**: If Zoho changes their URL structure or domain names, the detection may fail

## Future Enhancements

- Write support for creating and updating tasks in Zoho
- Caching of probe results to reduce repeated queries
- Support for VEVENT-to-task mapping if Zoho stores tasks as events
- More sophisticated detection heuristics based on server headers

## Testing

### Manual Testing with curl

To verify that a Zoho calendar doesn't advertise VTODO support:

```bash
curl -X PROPFIND 'https://calendar.zoho.com/caldav/username/zohoTask_123456789/' \
  -u 'username:password' \
  -H 'Content-Type: application/xml' \
  -H 'Depth: 0' \
  -d '<?xml version="1.0" encoding="utf-8"?>
<d:propfind xmlns:d="DAV:" xmlns:cal="urn:ietf:params:xml:ns:caldav">
  <d:prop>
    <d:resourcetype/>
    <d:displayname/>
    <cal:supported-calendar-component-set/>
  </d:prop>
</d:propfind>'
```

Expected: No `supported-calendar-component-set` or it doesn't include VTODO.

To test probing for VTODOs:

```bash
curl -X REPORT 'https://calendar.zoho.com/caldav/username/zohoTask_123456789/' \
  -u 'username:password' \
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
</cal:calendar-query>'
```

Expected: Returns VTODO items if the calendar contains tasks.

## Code Structure

- **Location**: `core/Services/CalDAV/Providers/Zoho.vala`
- **Main class**: `Services.CalDAV.Providers.Zoho`
- **Enum**: `Services.CalDAV.Providers.ZohoProbeResult`
- **Integration**: `core/Services/CalDAV/CalDAVClient.vala` (minimal changes to `fetch_project_list()` and `sync()`)

## References

- [CalDAV RFC 4791](https://tools.ietf.org/html/rfc4791)
- [CalDAV: Scheduling Extensions (RFC 6638)](https://tools.ietf.org/html/rfc6638)
- Planify Issue: (reference the specific GitHub issue that triggered this implementation)
