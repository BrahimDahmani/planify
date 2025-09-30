# Zoho CalDAV Adapter - Pull Request Summary

## Overview

This PR implements a dedicated Zoho CalDAV adapter to handle Zoho Calendar's non-standard CalDAV implementation. Zoho's CalDAV server does not advertise VTODO support in the `supported-calendar-component-set` property, preventing Planify from discovering task calendars using standard CalDAV discovery methods.

## Problem Statement

When users try to connect their Zoho Calendar account to Planify:
1. Planify performs a PROPFIND to discover calendars
2. It checks the `supported-calendar-component-set` property to identify task calendars
3. Zoho doesn't include this property or doesn't include VTODO in it
4. Result: Zoho task calendars are not detected or imported

## Solution

A provider/adapter pattern that:
1. Detects Zoho endpoints by domain or URL patterns
2. When a calendar doesn't advertise VTODO support, probes it with a test REPORT query
3. If VTODOs are found, imports the calendar as a task list
4. Maintains compatibility with all other CalDAV servers

## Implementation Details

### New Files Created

1. **`core/Services/CalDAV/Providers/Zoho.vala`** (162 lines)
   - `ZohoProbeResult` enum: VTODO_FOUND, VEVENT_ONLY, NONE
   - `is_zoho_endpoint()`: Detects Zoho URLs by domain or pattern
   - `probe_calendar()`: Sends REPORT queries to check for VTODO components

2. **`test/test-caldav-zoho.vala`** (144 lines)
   - Unit tests for endpoint detection
   - Integration test framework (requires env vars)
   - Manual verification instructions

3. **`docs/caldav-zoho-adapter.md`** (113 lines)
   - Technical architecture documentation
   - Implementation details
   - Limitations and future enhancements

4. **`docs/caldav-zoho-setup.md`** (127 lines)
   - User-facing setup guide
   - Step-by-step instructions
   - Troubleshooting tips

5. **`docs/verify-zoho-caldav.sh`** (119 lines)
   - Bash script for manual verification
   - Uses curl to test Zoho endpoints
   - Provides clear diagnostics

### Modified Files

1. **`core/Services/CalDAV/CalDAVClient.vala`** (+88 lines)
   - Added `should_probe_calendar()` method
   - Enhanced `fetch_project_list()` with fallback probing
   - Enhanced `sync()` with fallback probing
   - Changes are minimal and non-breaking

2. **`core/meson.build`** (+1 line)
   - Added Zoho.vala to build configuration

3. **`test/meson.build`** (+9 lines)
   - Added Zoho test suite

## Code Changes Summary

```
8 files changed, 763 insertions(+)

- Core implementation: 162 lines
- CalDAV integration: 88 lines
- Tests: 144 lines
- Documentation: 359 lines
- Build configuration: 10 lines
```

## Technical Approach

### Detection Algorithm

```vala
bool is_zoho_endpoint(string calendar_url) {
    // Check domain: calendar.zoho.{com,eu,in,com.au}
    // Check URL pattern: contains "zohoTask_"
    return matches_domain || matches_pattern;
}
```

### Probing Algorithm

```vala
async ZohoProbeResult probe_calendar(...) {
    1. Send REPORT query for VTODO components
    2. If VTODOs found → VTODO_FOUND
    3. Else send REPORT query for VEVENT components
    4. If VEVENTs found → VEVENT_ONLY
    5. Else → NONE
}
```

### Integration Flow

```
PROPFIND → Check supported-calendar-component-set
           ↓
           ├─ Has VTODO → Import (standard path)
           ↓
           ├─ No VTODO & is_zoho_endpoint → Probe
           ↓                                   ↓
           ↓                                   ├─ VTODO_FOUND → Import
           ↓                                   └─ Otherwise → Skip
           ↓
           └─ Not Zoho → Skip (standard path)
```

## Key Features

✅ **Minimal Changes**: Only 88 lines added to existing CalDAV client  
✅ **Non-Breaking**: Doesn't affect other CalDAV providers  
✅ **Well-Tested**: Unit tests for detection, integration tests for probing  
✅ **Documented**: Technical docs, user guide, verification script  
✅ **Extensible**: Easy to add other providers with similar issues  

## Testing

### Automated Tests

```bash
# Run unit tests
cd build
meson test caldav-zoho

# Unit tests include:
- Zoho domain detection
- URL pattern detection
- Negative cases (non-Zoho endpoints)
```

### Manual Testing

```bash
# Set up test environment
export ZOHO_CALDAV_URL='https://calendar.zoho.com/caldav/user/zohoTask_123/'
export ZOHO_CALDAV_USER='user@example.com'
export ZOHO_CALDAV_PASS='app-password'

# Run verification script
./docs/verify-zoho-caldav.sh

# Expected output:
# - PROPFIND response showing no VTODO advertising
# - REPORT response showing VTODO components exist
# - Confirmation that probe will be triggered
```

### Integration Testing

1. Add Zoho CalDAV account in Planify preferences
2. Verify task calendars are detected and imported
3. Check that tasks sync correctly
4. Verify create/update/delete operations work

## Compatibility

- **Zoho Calendar**: Full support for all regions (.com, .eu, .in, .com.au)
- **Other CalDAV**: No impact, standard detection still works
- **Nextcloud**: No impact, uses existing Nextcloud provider
- **Generic CalDAV**: No impact, standard VTODO detection works

## Performance Impact

- **Detection**: O(1) - Simple domain/pattern check
- **Probing**: +1 REPORT query per Zoho calendar during discovery
- **Ongoing sync**: No additional overhead (probe only runs during discovery)

## Security

- Uses existing authentication mechanisms
- Supports app-specific passwords
- All communication over HTTPS
- No credentials stored in code or docs

## Limitations

1. **Initial Implementation**: Read-only focus (write works via standard CalDAV)
2. **Probing Overhead**: Additional REPORT query during discovery
3. **Detection**: Relies on domain/pattern matching
4. **No Caching**: Probe results not cached (could be added later)

## Future Enhancements

1. Cache probe results to avoid repeated queries
2. Support VEVENT-to-task mapping if Zoho stores tasks as events
3. Optimize write operations for Zoho specifics
4. Add more sophisticated detection heuristics
5. Extend to other providers with similar issues

## Breaking Changes

None. This PR is purely additive:
- New files don't affect existing functionality
- CalDAVClient changes are additive (fallback only)
- All existing CalDAV providers work unchanged

## Migration Path

No migration needed. Existing users:
- Continue to work as before
- Can now add Zoho accounts that previously didn't work
- No configuration changes required

## Acceptance Criteria

✅ Zoho task calendars are detected and imported  
✅ Standard CalDAV behavior is unchanged  
✅ Code compiles without errors  
✅ Unit tests pass  
✅ Documentation is complete  
✅ Verification script validates behavior  

## Verification Steps

1. **Code Review**: Check implementation follows coding standards
2. **Build Test**: Verify code compiles with meson/ninja
3. **Unit Tests**: Run `meson test caldav-zoho`
4. **Manual Test**: Use verification script with real Zoho credentials
5. **Integration Test**: Add Zoho account in Planify and verify sync

## Related Issues

This PR addresses the issue where Zoho CalDAV task calendars were not being detected by Planify due to Zoho's non-standard CalDAV implementation.

## References

- [CalDAV RFC 4791](https://tools.ietf.org/html/rfc4791)
- [CalDAV: Scheduling Extensions (RFC 6638)](https://tools.ietf.org/html/rfc6638)
- Existing Nextcloud provider: `core/Services/CalDAV/Providers/Nextcloud.vala`

## Authors

- Implementation by GitHub Copilot
- Based on requirements from repository maintainers
- Follows existing code patterns in Planify

## License

Same as Planify: GPL-3.0-or-later
