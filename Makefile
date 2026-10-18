.PHONY: dev-up dev-down test lint

COMPOSE ?= docker compose -f syncro1/docker/docker-compose.yml

dev-up:
	@test -f .env || (cp .env.example .env && echo 'Created .env from .env.example; review it before rerunning make dev-up')
	$(COMPOSE) up --build -d
	$(COMPOSE) ps

dev-down:
	$(COMPOSE) down

lint:
	$(COMPOSE) run --rm php-fpm sh -lc 'find /var/www/mantis/plugins/Syncro1 /var/www/mantis/syncro1 -type f -name "*.php" -print0 | xargs -0 -n1 php -l'
	@if command -v shellcheck >/dev/null 2>&1; then shellcheck syncro1/scripts/send-emails syncro1/scripts/post-install-lockdown syncro1/deploy/*.sh syncro1/deploy/deploy-release syncro1/deploy/enable-tls syncro1/tests/smoke.sh syncro1/infra/terraform/user-data.sh; else echo 'UNVERIFIED: shellcheck not installed'; fi
	@if command -v terraform >/dev/null 2>&1; then terraform -chdir=syncro1/infra/terraform fmt -check; else echo 'UNVERIFIED: terraform not installed'; fi

test:
	$(COMPOSE) exec -T php-fpm php /var/www/mantis/syncro1/tests/test_email_policy.php
	$(COMPOSE) exec -T php-fpm /var/www/mantis/syncro1/scripts/audit-users.php
	$(COMPOSE) exec -T php-fpm php /var/www/mantis/syncro1/scripts/healthcheck.php
	SYNCRO1_BASE_URL=http://localhost:8080 MAILPIT_URL=http://localhost:8025 syncro1/tests/smoke.sh
