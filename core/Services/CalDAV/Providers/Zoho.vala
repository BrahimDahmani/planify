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

public enum Services.CalDAV.Providers.ZohoProbeResult {
    VTODO_FOUND,
    VEVENT_ONLY,
    NONE
}

public class Services.CalDAV.Providers.Zoho : Object {

    /**
     * Detects if the given URL is a Zoho CalDAV endpoint
     * 
     * @param calendar_url The calendar URL to check
     * @return true if this is a Zoho endpoint
     */
    public static bool is_zoho_endpoint (string calendar_url) {
        if (calendar_url == null || calendar_url == "") {
            return false;
        }

        try {
            var uri = GLib.Uri.parse (calendar_url, GLib.UriFlags.NONE);
            string host = uri.get_host ();
            
            // Check for Zoho domains
            if (host != null && (
                host.has_suffix ("calendar.zoho.com") ||
                host.has_suffix ("calendar.zoho.eu") ||
                host.has_suffix ("calendar.zoho.in") ||
                host.has_suffix ("calendar.zoho.com.au")
            )) {
                return true;
            }

            // Check for Zoho-specific URL patterns
            string path = uri.get_path ();
            if (path != null && path.contains ("zohoTask_")) {
                return true;
            }
        } catch (Error e) {
            warning ("Failed to parse URL for Zoho detection: %s", e.message);
        }

        return false;
    }

    /**
     * Probes a calendar to determine what component types it supports
     * 
     * @param calendar_url The calendar URL to probe
     * @param session The Soup session to use
     * @param base_url The base URL for resolving relative paths
     * @param username The username for authentication
     * @param password The password for authentication
     * @param cancellable Cancellable for the operation
     * @param ignore_ssl Whether to ignore SSL errors
     * @return The probe result indicating what components are supported
     */
    public static async ZohoProbeResult probe_calendar (
        string calendar_url,
        Soup.Session session,
        string base_url,
        string username,
        string password,
        GLib.Cancellable cancellable,
        bool ignore_ssl = false
    ) throws GLib.Error {
        // First, try a REPORT to check for VTODO components
        var vtodo_xml = """<?xml version="1.0" encoding="utf-8"?>
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
        </cal:calendar-query>
        """;

        try {
            var caldav_client = new Services.CalDAV.CalDAVClient (
                session,
                base_url,
                username,
                password,
                ignore_ssl
            );

            // Try to query for VTODO components (limit to 1 result if possible)
            var multi_status = yield caldav_client.report (calendar_url, vtodo_xml, "1", cancellable);
            
            // If we get any responses with VTODO data, the calendar supports VTODOs
            var responses = multi_status.responses ();
            if (responses.size > 0) {
                // Check if any response has calendar-data with VTODO
                foreach (var response in responses) {
                    foreach (var propstat in response.propstats ()) {
                        var calendar_data = propstat.get_first_prop_with_tagname ("calendar-data");
                        if (calendar_data != null) {
                            string content = calendar_data.text_content;
                            if (content != null && content.contains ("VTODO")) {
                                return ZohoProbeResult.VTODO_FOUND;
                            }
                        }
                    }
                }
            }

            // If no VTODOs found, try probing for VEVENTs
            var vevent_xml = """<?xml version="1.0" encoding="utf-8"?>
            <cal:calendar-query xmlns:d="DAV:" xmlns:cal="urn:ietf:params:xml:ns:caldav">
                <d:prop>
                    <d:getetag/>
                    <cal:calendar-data/>
                </d:prop>
                <cal:filter>
                    <cal:comp-filter name="VCALENDAR">
                        <cal:comp-filter name="VEVENT"/>
                    </cal:comp-filter>
                </cal:filter>
            </cal:calendar-query>
            """;

            multi_status = yield caldav_client.report (calendar_url, vevent_xml, "1", cancellable);
            responses = multi_status.responses ();
            
            if (responses.size > 0) {
                return ZohoProbeResult.VEVENT_ONLY;
            }

            return ZohoProbeResult.NONE;

        } catch (Error e) {
            // If the REPORT fails, we can't determine the type
            warning ("Failed to probe calendar at %s: %s", calendar_url, e.message);
            throw e;
        }
    }
}
