test_caldav_integration = executable(
    'test-caldav-integration',
    'test-caldav-integration.vala',
    dependencies: [ core_dep, glib_dep ],
    install: false
)

test('caldav-integration', test_caldav_integration, timeout: 60, suite: ['caldav-integration'])

test_caldav_zoho = executable(
    'test-caldav-zoho',
    'test-caldav-zoho.vala',
    dependencies: [ core_dep, glib_dep ],
    install: false
)

test('caldav-zoho', test_caldav_zoho, timeout: 60, suite: ['caldav-zoho'])

