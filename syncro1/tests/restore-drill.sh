#!/bin/sh
set -eu

if [ "${RESTORE_DRILL_CONFIRM:-}" != YES ]; then
	echo 'This destroys the local Docker volumes. Re-run with RESTORE_DRILL_CONFIRM=YES.' >&2
	exit 1
fi

compose_file=${COMPOSE_FILE:-syncro1/docker/docker-compose.yml}
root_password=${MYSQL_ROOT_PASSWORD:-change-root-local-password}
work_dir=${RESTORE_DRILL_DIR:-$(mktemp -d "${TMPDIR:-/tmp}/syncro1-restore.XXXXXX")}
mkdir -p "$work_dir"

compose() {
	docker compose -f "$compose_file" "$@"
}

mysql_query() {
	compose exec -T mysql mysql -uroot "-p${root_password}" mantis -NBe "$1"
}

echo "Restore drill evidence: $work_dir"
echo 'Capturing database dump, upload archive, counts, and upload checksums.'
compose exec -T mysql mysqldump --single-transaction --routines --triggers --hex-blob -uroot "-p${root_password}" mantis > "$work_dir/mantis.sql"
compose exec -T php-fpm tar -C /var/lib/syncro1/uploads -czf - . > "$work_dir/uploads.tar.gz"
mysql_query "SELECT CONCAT('users=', COUNT(*)) FROM mantis_user_table; SELECT CONCAT('issues=', COUNT(*)) FROM mantis_bug_table; SELECT CONCAT('attachments=', COUNT(*)) FROM mantis_bug_file_table;" > "$work_dir/before-counts.txt"
compose exec -T php-fpm sh -c 'find /var/lib/syncro1/uploads -type f -exec sha256sum {} \; | sort' > "$work_dir/before-uploads.sha256"
cat "$work_dir/before-counts.txt"
echo "before_upload_checksums=$(wc -l < "$work_dir/before-uploads.sha256" | tr -d ' ')"

echo 'Destroying Docker volumes and creating a clean stack.'
compose down -v
compose up --build -d

i=0
until curl --fail --silent http://localhost:8080/healthz >/dev/null; do
	i=$((i + 1))
	if [ "$i" -ge 60 ]; then
		echo 'Clean stack did not become healthy.' >&2
		exit 1
	fi
	sleep 2
done

echo 'Restoring database dump and upload archive.'
cat "$work_dir/mantis.sql" | compose exec -T mysql mysql -uroot "-p${root_password}" mantis
cat "$work_dir/uploads.tar.gz" | compose exec -T php-fpm tar -xzf - -C /var/lib/syncro1/uploads
compose exec -T php-fpm chown -R www-data:www-data /var/lib/syncro1/uploads

mysql_query "SELECT CONCAT('users=', COUNT(*)) FROM mantis_user_table; SELECT CONCAT('issues=', COUNT(*)) FROM mantis_bug_table; SELECT CONCAT('attachments=', COUNT(*)) FROM mantis_bug_file_table;" > "$work_dir/after-counts.txt"
compose exec -T php-fpm sh -c 'find /var/lib/syncro1/uploads -type f -exec sha256sum {} \; | sort' > "$work_dir/after-uploads.sha256"
cat "$work_dir/after-counts.txt"
echo "after_upload_checksums=$(wc -l < "$work_dir/after-uploads.sha256" | tr -d ' ')"

cmp "$work_dir/before-counts.txt" "$work_dir/after-counts.txt"
cmp "$work_dir/before-uploads.sha256" "$work_dir/after-uploads.sha256"
compose exec -T php-fpm php /var/www/mantis/syncro1/scripts/healthcheck.php
echo 'RESTORE DRILL PASS: issue/user/attachment counts and upload checksums match.'
