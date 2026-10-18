# SYNCRO1 runbook

## Start and verify locally

```sh
make dev-up
make test
curl -fsS http://localhost:8080/healthz
```

Use Mailpit to inspect activation, password-reset, and issue notifications.
`syncro1/scripts/audit-users.php` must be run after changing
`ALLOWED_EMAIL_DOMAINS`.

## Accounts

Only administrators manage accounts. Disable a departing account with
`enabled = false`; do not delete it because issue history must retain its
actor. The bootstrap disables the installer-created `administrator` and `root`
accounts and gives them non-deliverable, allowed-domain placeholder addresses.

## Production deploy and rollback

1. Provision Terraform, confirm the RDS endpoint, SES DNS, EIP, and SSM access.
2. Populate `/etc/syncro1/syncro1.env` with required values and a stable crypto
   salt. Never regenerate the salt during a deploy.
3. Run `syncro1/deploy/provision-host.sh` once, then install the signed release:

   ```sh
   RELEASE_S3_URI=s3://bucket/releases/syncro1-TAG.tar.gz \
   RELEASE_SHA256_URI=s3://bucket/releases/syncro1-TAG.tar.gz.sha256 \
   RELEASE_TAG=TAG syncro1/deploy/deploy-release
   ```

   The script verifies the checksum, runs the schema installer, locks the
   installer, atomically switches `current`, reloads services, and rolls back
   the symlink if `/healthz` fails.
4. Confirm `systemctl status nginx php8.3-fpm`, the queue timer, and the deep
   localhost health check.

Rollback is `ln -sfn /opt/syncro1/releases/KNOWN_GOOD /opt/syncro1/current`
followed by service reloads. Do not roll back application code across a schema
change without following the Mantis upgrade compatibility notes.

## Email queue

Production enables `email_send_using_cronjob` and runs the supplied Mantis
`scripts/send_emails.php` through `syncro1-email-queue.timer` every minute.
Inspect queue failures in the application log and SES delivery metrics. Mailpit
is development-only.

## Backups and restore test

`backup-db.sh` creates a mode-0600 gzip dump. RDS automated backups are the
primary production recovery mechanism; the script is for non-RDS or an
additional logical backup.

```sh
syncro1/deploy/backup-db.sh
RESTORE_CONFIRM=YES syncro1/deploy/restore-db.sh /var/backups/syncro1/mantis-*.sql.gz
```

Test restore on a separate clean database at least once before launch and after
material schema changes. Verify projects, users, issue attachments, and the
email queue after restore.

## TLS and operations

Point DNS at the EIP, then run `syncro1/deploy/enable-tls APP_DOMAIN ADMIN_EMAIL`.
It installs the HTTP-to-HTTPS redirect and executes `certbot renew --dry-run`.
For domain changes, update SES identities, DNS, the allow-list, and run the
user audit before enabling the new configuration.

## Incident response

Use SSM, not SSH. Preserve logs and the database snapshot before changing data.
Rotate SMTP credentials and the crypto salt only with a planned session/token
impact review. Optional future controls include ClamAV, WAF, S3 attachments,
2FA, and SSO.
