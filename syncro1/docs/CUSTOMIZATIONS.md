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

## No other core edits

Branding, workflow helpers, domain policy, bootstrap, seed data, deployment,
and hardening live in `plugins/Syncro1/` and `syncro1/`.
