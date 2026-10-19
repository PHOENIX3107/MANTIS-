# Acceptance evidence

Results below are from commands actually executed in this workspace on
2026-10-19 (Asia/Kolkata). `UNVERIFIED` means the requested check could not be
completed locally; it is not a pass.

| ID | Status | Executed evidence |
|---|---|---|
| AC-1 | PASS | `RESTORE_DRILL_CONFIRM=YES syncro1/tests/restore-drill.sh` rebuilt the stack, installed the schema, restored data, and ended with `healthcheck.php ... ok`. |
| AC-2 | PASS | `docker compose ... exec php-fpm syncro1/scripts/verify-config-options` printed `All template assignments have upstream definitions.`; `curl /` returned `HTTP/1.1 302 Found` and `Location: http://localhost:8080/login_page.php`. |
| AC-3 | PASS | `npm run test:e2e -- --reporter=line` included `AC-3: administrator creates user and developers; Mailpit activation sets passwords`; final result `10 passed (2.3m)`. The additional temporary-password test `npx playwright test e2e/temporary-password.spec.js --reporter=line` ended `1 passed (14.7s)` and verified MySQL hashing, no activation email, temporary-password login/change, and short-password rejection. |
| AC-4 | PASS | The same Playwright run included `AC-4: invalid domains are rejected on create, administrator edit, and self edit`; final result `10 passed (2.3m)`. |
| AC-5 | UNVERIFIED | `make test` executed the 12 email-policy cases and user audit, but no separate authenticated authorization matrix for every AC-5 threshold was executed. |
| AC-6 | PASS | Playwright AC-6 created a private report with `fixture.txt`, verified the reporter/developer attachment link, and verified the second user was denied; final suite `10 passed (2.3m)`. |
| AC-7 | PASS | Playwright AC-7 verified valid download headers/body and Dropzone refusal for `.php`, `.html`, `.svg`, and a 21 MiB file; final suite `10 passed (2.3m)`. |
| AC-8 | PASS | Playwright AC-8 completed Raise ticket and Start work; the concurrency test repeated the race 20 times and final suite `10 passed (2.3m)`. |
| AC-9 | PASS | Playwright AC-9 resolved, reopened as the reporter, rejected reporter close, and verified status remained `10`; final suite `10 passed (2.3m)`. |
| AC-10 | PASS | Playwright AC-10 verified public note UI visibility and Mailpit recipient delivery, then private note UI visibility and zero issue-mail recipients for the private note; final suite `10 passed (2.3m)`. |
| AC-11 | PASS | Playwright checked `/admin/`, `/config/`, `/.git/`, `/vendor/`, `/doc/`, `/tests/`, SOAP, RSS, and three direct upload paths; all were `403` or `404`. Final suite `10 passed (2.3m)`. |
| AC-12 | PASS | Playwright checked nosniff, frame protection, `strict-origin-when-cross-origin`, and forced-download failure output for PHP errors; final suite `10 passed (2.3m)`. |
| AC-13 | PASS | Playwright requested lost password, found the Mailpit reset message, set a new password through the reset URL, and logged in with it; final suite `10 passed (2.3m)`. |
| AC-14 | PASS | Restore drill counts matched: `users=130`, `issues=48`, `attachments=12` before and after; upload manifests had `12` checksums before and after; `cmp` passed. |
| AC-15 | UNVERIFIED | Docker Terraform `fmt -check` and `validate` passed, but the required provider-backed `plan -var-file=terraform.tfvars.example` stopped with `Error: No valid credential sources found`; see `COST-REVIEW.md`. |
| AC-16 | PASS | Core diff against `release-2.28.4` resolved to `ceb74c8056753e0d4089af95bde794e47fa2ef53` and contained exactly the five files reconciled in `CUSTOMIZATIONS.md`; full-history Gitleaks output was `4 commits scanned`, `no leaks found`, `secret_scan_exit=0`. |

## Command output excerpts

```text
npm run test:e2e -- --reporter=line
10 passed (2.3m)

AC-8 concurrency results: ... round 1 ... round 20 ...
every round: status=60, winnerCount=1, handlerCount=1, actionCount=1

make test
Email policy cases passed: 12
All accounts match the configured email domains.
ok
HTTP and Mailpit smoke checks passed.

RESTORE_DRILL_CONFIRM=YES syncro1/tests/restore-drill.sh
users=130
issues=48
attachments=12
before_upload_checksums=12
users=130
issues=48
attachments=12
after_upload_checksums=12
ok
RESTORE DRILL PASS: issue/user/attachment counts and upload checksums match.

docker run ... terraform plan ... -var-file=terraform.tfvars.example
Error: No valid credential sources found

docker run ... gitleaks ... detect --log-opts='--all'
4 commits scanned.
no leaks found
secret_scan_exit=0
```
