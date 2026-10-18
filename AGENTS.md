# SYNCRO1 Bug Tracker

This repository is MantisBT 2.28.4 with SYNCRO1 customizations isolated in
`plugins/Syncro1/` and `syncro1/`. Keep upstream core changes to the documented
email-validation patch only, and preserve GPL headers.

## Local commands

- `make dev-up` — build and start the local Docker stack.
- `make dev-down` — stop the local stack and remove containers.
- `make lint` — PHP syntax checks, shellcheck when installed, and Terraform formatting checks.
- `make test` — plugin unit tests and configured smoke/e2e checks.
- `./syncro1/scripts/install-headless` — install Mantis schema in a running stack.
- `./syncro1/scripts/bootstrap` — create the configured admin and seed the project.

Do not commit `.env`, generated runtime config, uploads, database data, Mailpit
data, passwords, crypto salts, or AWS credentials. Runtime configuration comes
from environment variables or a secret-rendered production file.

