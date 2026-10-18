# MantisBT and SYNCRO1 upgrade procedure

1. Read the target Mantis release notes and review the upstream tag. Keep the
   current release available for rollback.
2. In a clean working directory, merge or rebase the new upstream
   `release-2.*` tag. Re-apply only the documented `SYNCRO1-PATCH` changes and
   rerun the source option/event verification.
3. Copy `syncro1/config/config_inc.php`, `custom_constants_inc.php`, and
   `custom_strings_inc.php` into the release `config/` directory through the
   build/deploy process. Do not commit production secrets.
4. Build the Docker image and run the clean headless install plus tests.
5. On staging, take a database and uploads backup, run
   `syncro1/deploy/upgrade-release.sh`, and inspect the Mantis admin/check
   output before locking `admin/`.
6. Publish the release tarball and SHA-256 file, then use `deploy-release` for
   the atomic production switch.

The upstream upgrade flow is: use a clean directory, preserve/copy the config
and `custom_*` files, run the schema upgrade, then remove or lock `admin/`.
Do not skip the SYNCRO1 email-policy regression tests when changing Mantis core.
