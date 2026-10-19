# SYNCRO1 assumptions and decisions

- **A1 — ticket terminology:** Mantis issues are the ticket record. “Raise ticket”
  is status 30 (`Ticket raised`); “Start work” is status 60 (`In progress`) with
  the current developer as handler. No second child-ticket system is created for MVP.
- The reporter visibility switch is `limit_view_unless_threshold = DEVELOPER`.
  Mantis 2.28.4 deprecates `limit_reporters`.
- Admin-created accounts default to Mantis’s activation/password token flow. The
  admin may instead set a temporary password (minimum 12 characters); that value
  is stored only as a password hash in MySQL and is never logged or emailed.
- Admin-created users may be disabled with `enabled = false`; deletion is not the
  operational path because history must remain attributable.
- Admin bootstrap requires a 16-character password and an allowed-domain email.
- The strict email validator is connected through a small documented core patch
  because Mantis 2.28.4 only exposes `EVENT_MANAGE_USER_CREATE/UPDATE` after the
  database mutation and has no pre-mutation email event.
- REST and SOAP are disabled at the nginx boundary for this deployment. The core
  validator still protects direct API calls and CLI calls when those entry points
  are enabled for controlled administration.
- Uploads use Mantis DISK storage outside the document root. The application and
  web server both enforce the same allow-list and size limit.
- Development uses Mailpit. Production uses SMTP submission (587/STARTTLS), an
  email queue, and a systemd timer.
- The deployment uses a static `/healthz` nginx response plus a localhost-only PHP
  deep check. AWS APIs are never called by tests in this repository.
- The supplied placeholder branding assets are intentionally generic and must be
  replaced by SYNCRO1-owned assets before production launch.

