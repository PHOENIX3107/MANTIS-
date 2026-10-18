# SYNCRO1 Bug Tracker

This repository is a pinned MantisBT 2.28.4 application with SYNCRO1 policy,
workflow, branding, Docker, and AWS deployment templates.

## Local quick start

```sh
cp .env.example .env
# Change ADMIN_INITIAL_PASSWORD and the local placeholder secrets if desired.
make dev-up
make test
```

Open <http://localhost:8080/> and Mailpit at <http://localhost:8025/>. The
first boot installs the schema, creates the `syn_admin` account, seeds the
default project, enables the SYNCRO1 plugin, and moves the installer directory
outside the served release. To reset only the disposable local environment:

```sh
docker compose -f syncro1/docker/docker-compose.yml down -v
```

The production flow is intentionally separate: provision an EC2 host, populate
`/etc/syncro1/syncro1.env` from SSM/Secrets Manager, publish a checksumed release
tarball to the private artifact bucket, and run `syncro1/deploy/deploy-release`.
See [RUNBOOK.md](docs/RUNBOOK.md), [ARCHITECTURE.md](docs/ARCHITECTURE.md), and
the Terraform example under `syncro1/infra/terraform/`.
