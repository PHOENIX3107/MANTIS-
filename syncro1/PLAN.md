# SYNCRO1 implementation plan

## Reconnaissance

- The workspace was empty, so the upstream repository was cloned directly.
- Baseline: MantisBT `2.28.4`, commit `ceb74c8056753e0d4089af95bde794e47fa2ef53`,
  selected from the latest available `release-2.28.4` tag.
- PHP support in the checked-out `composer.json` is `^7.4 || ^8.0`; the local
  stack will use PHP 8.3 as requested.
- Mantis loads `config/config_inc.php`, `config/custom_constants_inc.php`, and
  `config/custom_strings_inc.php`; this is the supported customization path.
- Confirmed native options include `allow_signup`, `allow_anonymous_login`,
  `limit_email_domains`, `limit_view_unless_threshold` (the replacement for
  deprecated `limit_reporters`), `email_send_using_cronjob`, `allowed_files`,
  `disallowed_files`, `max_file_size`, `bug_*_page_fields`, `handle_bug_threshold`,
  `set_status_threshold`, `allow_reporter_reopen`, `allow_reporter_close`, and
  `crypto_master_salt`.
- Confirmed `EVENT_MENU_ISSUE`, `EVENT_LAYOUT_RESOURCES`, report/update events,
  account events, and management-user events. No upstream pre-create/pre-update
  user-email hook exists in this version.
- Confirmed Mantis has built-in statuses 10, 20, 30, 40, 50, 80, and 90. Status
  60 is not built in and will be defined by the SYNCRO1 custom constants/string
  configuration.
- The legacy `limit_reporters` setting is deprecated in this version; the
  implementation uses `limit_view_unless_threshold`.
- The upstream repository does not provide a `scripts/send_emails.php` wrapper
  at this tag; it does provide `scripts/send_emails.php` in the checked-out
  tree and the native `email_send_using_cronjob` setting. The deployment wrapper
  will call the native script through the CLI.

## Assumptions and safety decisions

1. An issue is already a ticket. “Raise ticket” means moving a bug to status 30;
   “Start work” means assigning the current developer and moving it to status 60.
2. User email addresses are mandatory. The strict validator rejects blank,
   whitespace-padded, subdomain, lookalike, and malformed addresses even where
   the upstream domain option is permissive.
3. Account creation remains administrator-only. Mantis’s password-reset email is
   used for admin-created users; the admin does not set a permanent password.
4. `limit_view_unless_threshold = DEVELOPER` is the single visibility switch:
   reporters see only issues they reported/monitor/handle, while developers and
   administrators see all permitted project issues.
5. The local Docker stack is the executable acceptance environment. AWS files
   are safe templates and are not applied from this workspace.

See `docs/ASSUMPTIONS.md` for the complete decision log.

## Milestones

1. Recon and plan — this file, assumptions, configuration verification skeleton.
2. Local dev stack — PHP-FPM, nginx, MySQL 8.4, Mailpit, queue worker, headless install.
3. Core configuration and roles — access levels, workflow, visibility, disabled features.
4. Accounts and domain control — bootstrap, default-admin lockdown, strict email validation,
   audit CLI, password reset flow.
5. Issue flow — project/category/custom-field seeds, attachments, queue, notifications,
   developer actions, visibility and workflow tests.
6. Branding and hardening — plugin branding, headers, PHP/nginx policy, admin lockdown.
7. AWS and operations — Terraform, provisioning, atomic deploy/rollback, backups, monitoring.
8. CI/CD, docs, and final verification — acceptance evidence and core-diff report.

Each completed milestone is committed with a clear message. Any check that cannot
be executed locally is marked `UNVERIFIED` with the exact command in
`docs/ACCEPTANCE.md`.

