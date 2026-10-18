# Configuration verification

This file maps every SYNCRO1 Mantis option to the checked-out upstream source.
Line numbers are refreshed by `syncro1/scripts/verify-config-options`.

| SYNCRO1 setting | Upstream definition / evidence | Status |
|---|---|---|
| `crypto_master_salt` | `config_defaults_inc.php` near the crypto section; `admin/check/check_crypto_inc.php` validates it | verified |
| `allow_signup` | `config_defaults_inc.php` signup section | verified |
| `allow_anonymous_login` | `config_defaults_inc.php` anonymous access section | verified |
| `max_failed_login_count` | `config_defaults_inc.php` signup/login section | verified |
| `limit_email_domains` | `config_defaults_inc.php` email section; array of domains | verified |
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
| `status_enum_string` | `config_defaults_inc.php` status enum section | verified |
| `status_colors` | `config_defaults_inc.php` status color section | verified |
| `access_levels_enum_string` | `config_defaults_inc.php` role enum section | verified |
| `enable_sponsorship` | `config_defaults_inc.php` sponsorship section | verified |
| `time_tracking_enabled` | `config_defaults_inc.php` time tracking section | verified |
| `enable_syndication` / RSS | checked by grep; no SYNCRO1 override is used unless the exact option exists | pending script refresh |

## Candidate options not used without a source definition

- `email_send_using_cronjob` exists and is used.
- `limit_reporters` exists but is deprecated; `limit_view_unless_threshold` is used.
- No guessed `allow_self_signup` or `enable_rest_api` option is set. Signup and
  API exposure are controlled by the verified Mantis settings and nginx policy.
- The custom status constant `IN_PROGRESS` is SYNCRO1-owned, not an upstream option.

