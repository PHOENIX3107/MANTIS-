# Acceptance evidence

Status reflects commands executed in this workspace on 2026-10-19 (Asia/Kolkata).
`UNVERIFIED` means the implementation is present but the required browser,
production AWS, or destructive restore test was not run here.

| ID | Status | Evidence / command |
|---|---|---|
| AC-1 | PASS | `docker compose ... up --build -d`; schema, bootstrap, project, plugin, marker, locked installer, and `/healthz/deep` verified. |
| AC-2 | PASS | Config verification plus anonymous root redirect to `login_page.php`; signup is OFF. |
| AC-3 | UNVERIFIED | Admin UI and Mailpit activation/password-set flow still requires a browser session. |
| AC-4 | PASS / UNVERIFIED | 12 pure policy cases, bootstrap, CLI create path, and audit passed; every UI/API path still needs browser/API coverage. |
| AC-5 | UNVERIFIED | Thresholds are configured; developer/browser authorization matrix needs an authenticated e2e test. |
| AC-6 | UNVERIFIED | Seed and upload configuration exist; two-user visibility and media upload need e2e coverage. |
| AC-7 | UNVERIFIED | Allow/deny lists and safe download headers are configured; oversize and executable upload need e2e coverage. |
| AC-8 | UNVERIFIED | Atomic plugin action pages and race checks are implemented; authenticated two-developer run is pending. |
| AC-9 | UNVERIFIED | Workflow map and plugin guard are present; full role transition matrix is pending. |
| AC-10 | UNVERIFIED | Native private-note thresholds are configured; visibility and email assertions need e2e coverage. |
| AC-11 | PASS | `syncro1/tests/smoke.sh` checks health, headers, admin/config/git/vendor/API/RSS blocking against `http://localhost:8080`. |
| AC-12 | PASS | Local HTTP response showed security headers; PHP error display is OFF in config/template. |
| AC-13 | UNVERIFIED | Lost-password rate limiting/config is present; Mailpit non-disclosure behavior needs browser verification. |
| AC-14 | UNVERIFIED | Backup/restore scripts and timers exist; clean-database restore test was not run. |
| AC-15 | PASS | Docker runtime checks passed; Docker-based ShellCheck and Terraform provider-backed `fmt/init/validate` passed. |
| AC-16 | PASS | Core changes are limited to the documented `SYNCRO1-PATCH` files in `CUSTOMIZATIONS.md`. |

Local checks that passed:

```text
Docker image build: PASS
Mantis schema bootstrap: PASS (214 steps)
Email policy unit cases: PASS (12)
Audit users: PASS
Config option verification: PASS
Deep database health: PASS
HTTP/Mailpit smoke: available as syncro1/tests/smoke.sh
ShellCheck: PASS (container)
Terraform fmt/init/validate: PASS (container)
```
