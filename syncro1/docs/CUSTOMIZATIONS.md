# SYNCRO1 customizations

## Upstream core patch

MantisBT 2.28.4 exposes `EVENT_MANAGE_USER_CREATE` and
`EVENT_MANAGE_USER_UPDATE` only after the mutation. Because email-domain
restriction is security-critical and must protect admin UI, self-service,
REST/SOAP, and CLI paths, the smallest safe patch adds the declared
`EVENT_USER_EMAIL_VALIDATE` event and invokes it before `user_create()` inserts
or `user_set_email()` updates the address. The plugin callback throws a native
`ClientException` on invalid addresses.

Files: `core/events_inc.php`, `core/user_api.php`,
`core/commands/UserCreateCommand.php`, `core/commands/UserUpdateCommand.php`,
and `account_update.php` (the latter three preserve raw form/API input so
whitespace-padded addresses cannot be silently normalized before validation).

Test: `syncro1/tests/test_email_policy.php`, plus the Docker smoke path through
the Mantis UI/API when enabled. Re-apply and review this patch after every
upstream Mantis security upgrade.

## Admin temporary password path

The native create-user page now offers an explicit temporary-password option
when email activation is enabled. The server validates the confirmation and a
12-character minimum, passes the supplied value only through the authenticated
admin command, stores only Mantis's password hash in MySQL, and suppresses the
activation email for that account. Leaving the option unchecked preserves the
native activation-email behavior.

Files: `manage_user_create_page.php`, `manage_user_create.php`,
`core/commands/UserCreateCommand.php`, and `core/user_api.php`.

Test: `npx playwright test e2e/temporary-password.spec.js --reporter=line`
ended with `1 passed (14.7s)`; the test also verified no plaintext password in
MySQL, no activation message in Mailpit, temporary-password login, password
change, and server-side rejection of a short password.

## Other implementation files

Branding, workflow helpers, domain policy, bootstrap, seed data, deployment,
and hardening live in `plugins/Syncro1/` and `syncro1/`.
