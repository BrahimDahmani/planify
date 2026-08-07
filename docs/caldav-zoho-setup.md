# Setting Up Zoho CalDAV in Planify

## Overview

Planify now supports Zoho Calendar through CalDAV integration. This guide will help you set up your Zoho Calendar account with Planify to sync your tasks.

## Prerequisites

1. A Zoho Calendar account
2. Zoho app-specific password (recommended for security)

## Steps

### 1. Generate an App-Specific Password (Recommended)

For security reasons, it's recommended to use an app-specific password instead of your main Zoho password:

1. Log in to your Zoho account
2. Go to [Zoho Account Settings](https://accounts.zoho.com/home#security)
3. Navigate to "Security" → "App Passwords"
4. Click "Generate New Password"
5. Name it "Planify" or similar
6. Copy the generated password

### 2. Find Your Zoho CalDAV Server URL

The Zoho CalDAV server URL depends on your region:

- **Zoho.com (Global)**: `https://calendar.zoho.com/caldav/`
- **Zoho.eu (Europe)**: `https://calendar.zoho.eu/caldav/`
- **Zoho.in (India)**: `https://calendar.zoho.in/caldav/`
- **Zoho.com.au (Australia)**: `https://calendar.zoho.com.au/caldav/`

### 3. Add CalDAV Account in Planify

1. Open Planify
2. Go to **Preferences** → **Accounts**
3. Click **Add Account**
4. Select **CalDAV** or **Generic CalDAV**
5. Enter your details:
   - **Server URL**: Your Zoho CalDAV URL (from step 2)
   - **Username**: Your Zoho email address
   - **Password**: Your app-specific password (from step 1) or account password
6. Click **Connect** or **Sign In**

### 4. Wait for Synchronization

Planify will:
1. Connect to your Zoho account
2. Discover your task calendars
3. Import your tasks

This may take a few moments depending on how many tasks you have.

## Features

### Supported

- ✅ View Zoho tasks in Planify
- ✅ Sync task title, description, and due dates
- ✅ Mark tasks as complete/incomplete
- ✅ Create new tasks
- ✅ Update existing tasks
- ✅ Delete tasks
- ✅ Automatic synchronization

### Limitations

- Tasks are imported from calendars that contain VTODO components
- Some Zoho-specific features may not be available
- Synchronization happens periodically (not real-time)

## Troubleshooting

### Tasks Not Appearing

If your Zoho tasks don't appear in Planify:

1. **Check your calendar type**: Make sure you're looking at a Task calendar in Zoho, not an Event calendar
2. **Verify credentials**: Ensure your username and app password are correct
3. **Check server URL**: Verify you're using the correct regional Zoho URL
4. **Force sync**: Try manually syncing by clicking the sync button in Planify

### Authentication Errors

If you get authentication errors:

1. Verify your Zoho email and password/app password
2. Try regenerating a new app-specific password
3. Check that your Zoho account is active and not locked

### Calendar Not Detected

If Planify doesn't detect your Zoho task calendar:

1. Verify in Zoho Calendar web interface that you have a Tasks calendar
2. Create at least one task in Zoho to ensure the calendar is active
3. Check Planify logs for any error messages

## Technical Details

Planify uses the Zoho CalDAV adapter which:

- Automatically detects Zoho Calendar endpoints
- Probes calendars to find task lists even when not advertised
- Syncs VTODO components (CalDAV tasks) with Planify tasks

For more technical information, see [docs/caldav-zoho-adapter.md](caldav-zoho-adapter.md).

## Security Notes

- **Use app-specific passwords**: Don't use your main Zoho password
- **Credentials are stored securely**: Planify uses your system's secure credential storage
- **HTTPS only**: All communication with Zoho is encrypted

## Getting Help

If you encounter issues:

1. Check the [Planify documentation](https://github.com/alainm23/planify)
2. Search or create an issue on [GitHub](https://github.com/alainm23/planify/issues)
3. Include relevant error messages and Planify logs

## Related Documentation

- [CalDAV Zoho Adapter Technical Documentation](caldav-zoho-adapter.md)
- [CalDAV RFC 4791](https://tools.ietf.org/html/rfc4791)
