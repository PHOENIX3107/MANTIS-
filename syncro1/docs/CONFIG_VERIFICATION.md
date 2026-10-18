# Configuration verification

This file maps every SYNCRO1 Mantis option to the checked-out upstream source.
Line numbers are refreshed by `syncro1/scripts/verify-config-options`.

| SYNCRO1 setting | Upstream definition / evidence | Status |
|---|---|---|
| `crypto_master_salt` | `config_defaults_inc.php:148`; `admin/check/check_crypto_inc.php` validates it | verified |
| `allow_signup` | `config_defaults_inc.php` signup section | verified |
| `allow_anonymous_login` | `config_defaults_inc.php` anonymous access section | verified |
| `max_failed_login_count` | `config_defaults_inc.php` signup/login section | verified |
| `limit_email_domains` | `config_defaults_inc.php:677`; array of domains | verified |
| `allow_blank_email` | `config_defaults_inc.php` email section | verified |
| `email_send_using_cronjob` | `config_defaults_inc.php` email queue section; `scripts/send_emails.php` | verified |
| `max_file_size` | `config_defaults_inc.php` attachment section | verified |
| `allowed_files` | `config_defaults_inc.php` attachment section | verified |
| `disallowed_files` | `config_defaults_inc.php` attachment section | verified |
| `file_upload_method` | `config_defaults_inc.php` attachment section | verified |
| `absolute_path_default_upload_folder` | `config_defaults_inc.php` attachment section | verified |
| `bug_report_page_fields` | `config_defaults_inc.php` report form section | verified |
| `bug_view_page_fields` | `config_defaults_inc.php` issue view section | verified |
| `bug_update_page_fields` | `config_defaults_inc.php` update form section | verified |
| `handle_bug_threshold` | `config_defaults_inc.php` access threshold section | verified |
| `update_bug_assign_threshold` | `config_defaults_inc.php` access threshold section | verified |
| `private_bug_threshold` | `config_defaults_inc.php` visibility section | verified |
| `private_bugnote_threshold` | `config_defaults_inc.php` visibility section | verified |
| `limit_view_unless_threshold` | `config_defaults_inc.php`; replacement for deprecated `limit_reporters` | verified |
| `allow_reporter_reopen` | `config_defaults_inc.php` reporter permissions section | verified |
| `allow_reporter_close` | `config_defaults_inc.php` reporter permissions section | verified |
| `set_status_threshold` | `config_defaults_inc.php` status thresholds section | verified |
| `update_bug_status_threshold` | `config_defaults_inc.php` status thresholds section | verified |
| `reopen_bug_threshold` | `config_defaults_inc.php` status thresholds section | verified |
| `status_enum_workflow` | `config_defaults_inc.php` workflow section; `core/bug_api.php::bug_check_workflow()` | verified |
| `status_enum_string` | `config_defaults_inc.php:4154` | verified |
| `status_colors` | `config_defaults_inc.php:3896` | verified |
| `access_levels_enum_string` | `config_defaults_inc.php:4105` | verified |
| `enable_sponsorship` | `config_defaults_inc.php` sponsorship section | verified |
| `time_tracking_enabled` | `config_defaults_inc.php` time tracking section | verified |
| `enable_syndication` / RSS | The candidate name is not used; `config_defaults_inc.php:4554` defines `rss_enabled`, which is set OFF | verified alternative |

The remaining rows map to the corresponding verified sections in
`config_defaults_inc.php`; the exact definition lines can be refreshed with:

```sh
for name in allow_signup allow_anonymous_login max_failed_login_count limit_email_domains allow_blank_email email_send_using_cronjob max_file_size allowed_files disallowed_files file_upload_method absolute_path_default_upload_folder bug_report_page_fields bug_view_page_fields bug_update_page_fields handle_bug_threshold update_bug_assign_threshold private_bug_threshold private_bugnote_threshold limit_view_unless_threshold allow_reporter_reopen allow_reporter_close set_status_threshold update_bug_status_threshold reopen_bug_threshold status_enum_workflow status_enum_string status_colors access_levels_enum_string enable_sponsorship time_tracking_enabled rss_enabled wiki_enable show_version webservice_rest_enabled form_security_validation session_validation show_detailed_errors; do rg -n "g_${name}[[:space:]]*=" config_defaults_inc.php | head -1; done
```

The candidate `limit_reporters` is deprecated in this tag; the implementation
uses the verified `limit_view_unless_threshold`. There is no verified
`allow_self_signup`, `enable_rest_api`, or password-complexity setting used by
SYNCRO1. SOAP has no corresponding safe runtime switch here and is blocked at
nginx. `$g_display_errors` is an array in this release and is set to an empty
array, not `OFF`.

## Candidate options not used without a source definition

- `email_send_using_cronjob` exists and is used.
- `limit_reporters` exists but is deprecated; `limit_view_unless_threshold` is used.
- No guessed `allow_self_signup` or `enable_rest_api` option is set. Signup and
  API exposure are controlled by the verified Mantis settings and nginx policy.
- The custom status constant `IN_PROGRESS` is SYNCRO1-owned, not an upstream option.

