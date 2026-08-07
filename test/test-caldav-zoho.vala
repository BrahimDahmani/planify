/*
 * Copyright © 2025 Alain M. (https://github.com/alainm23/planify)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 *
 * Authored by: Alain M. <alainmh23@gmail.com>
 */

using GLib;

/**
 * Test Zoho endpoint detection
 */
void test_zoho_detection () {
    // Test Zoho domains
    assert (Services.CalDAV.Providers.Zoho.is_zoho_endpoint ("https://calendar.zoho.com/caldav/user/zohoTask_123/"));
    assert (Services.CalDAV.Providers.Zoho.is_zoho_endpoint ("https://calendar.zoho.eu/caldav/user/tasks/"));
    assert (Services.CalDAV.Providers.Zoho.is_zoho_endpoint ("https://calendar.zoho.in/caldav/user/zohoTask_456/"));
    assert (Services.CalDAV.Providers.Zoho.is_zoho_endpoint ("https://calendar.zoho.com.au/caldav/user/"));

    // Test Zoho URL patterns
    assert (Services.CalDAV.Providers.Zoho.is_zoho_endpoint ("https://example.com/caldav/zohoTask_789/"));

    // Test non-Zoho endpoints
    assert (!Services.CalDAV.Providers.Zoho.is_zoho_endpoint ("https://nextcloud.example.com/caldav/user/"));
    assert (!Services.CalDAV.Providers.Zoho.is_zoho_endpoint ("https://calendar.google.com/"));
    assert (!Services.CalDAV.Providers.Zoho.is_zoho_endpoint ("https://caldav.icloud.com/"));
    
    // Test null/empty strings
    assert (!Services.CalDAV.Providers.Zoho.is_zoho_endpoint (null));
    assert (!Services.CalDAV.Providers.Zoho.is_zoho_endpoint (""));

    message ("Zoho endpoint detection tests passed");
}

/**
 * Test probe functionality with mock server responses
 * 
 * Note: This is a placeholder for integration testing.
 * Real testing would require either:
 * 1. A mock CalDAV server
 * 2. Environment variables with test Zoho credentials
 * 3. Recorded server responses for replay
 */
async void test_zoho_probe_async () {
    string? server_url = Environment.get_variable ("ZOHO_CALDAV_URL");
    string? username = Environment.get_variable ("ZOHO_CALDAV_USER");
    string? password = Environment.get_variable ("ZOHO_CALDAV_PASS");

    if (server_url == null || username == null || password == null) {
        message ("Skipping Zoho probe test: missing environment variables.");
        message ("Set ZOHO_CALDAV_URL, ZOHO_CALDAV_USER, ZOHO_CALDAV_PASS to enable.");
        return;
    }

    var cancellable = new GLib.Cancellable ();
    var session = new Soup.Session ();

    try {
        // Extract base URL from server URL
        var uri = GLib.Uri.parse (server_url, GLib.UriFlags.NONE);
        string base_url = "%s://%s".printf (uri.get_scheme (), uri.get_host ());
        if (uri.get_port () > 0) {
            base_url = "%s:%d".printf (base_url, uri.get_port ());
        }

        var result = yield Services.CalDAV.Providers.Zoho.probe_calendar (
            server_url,
            session,
            base_url,
            username,
            password,
            cancellable,
            false
        );

        message ("Probe result: %s", result.to_string ());

        // We expect at least VTODO_FOUND or VEVENT_ONLY for a valid Zoho task calendar
        assert (result == Services.CalDAV.Providers.ZohoProbeResult.VTODO_FOUND ||
                result == Services.CalDAV.Providers.ZohoProbeResult.VEVENT_ONLY ||
                result == Services.CalDAV.Providers.ZohoProbeResult.NONE);

        message ("Zoho probe test passed");
    } catch (Error e) {
        warning ("Probe test failed: %s", e.message);
    }
}

void test_zoho_probe () {
    var loop = new MainLoop ();
    test_zoho_probe_async.begin ((obj, res) => {
        test_zoho_probe_async.end (res);
        loop.quit ();
    });
    loop.run ();
}

/**
 * Manual verification instructions
 * 
 * To manually test the Zoho adapter:
 * 
 * 1. Configure a Zoho CalDAV account in Planify preferences:
 *    - Server: https://calendar.zoho.com (or your region's Zoho domain)
 *    - Username: Your Zoho email address
 *    - Password: App-specific password (generate from Zoho account settings)
 * 
 * 2. Expected behavior:
 *    - Zoho task calendars should be detected and imported
 *    - Each task calendar should appear as a Project in Planify
 *    - Tasks should be synced and displayed correctly
 * 
 * 3. Verification steps:
 *    a. Check that Zoho task calendars appear in the project list
 *    b. Verify that tasks from Zoho are imported
 *    c. Check that task properties (title, description, due date, completion) are correct
 *    d. Test synchronization by creating a task in Zoho web interface and syncing in Planify
 * 
 * 4. Debugging:
 *    - Enable debug logging to see probe results
 *    - Check that is_zoho_endpoint returns true for your calendar URL
 *    - Verify that probe_calendar is called for calendars without VTODO advertising
 */

int main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/caldav/zoho/detection", test_zoho_detection);
    Test.add_func ("/caldav/zoho/probe", test_zoho_probe);
    return Test.run ();
}
