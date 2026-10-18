#!/bin/sh
set -eu

if [ -f /etc/syncro1/syncro1.env ]; then
	# shellcheck disable=SC1091
	. /etc/syncro1/syncro1.env
fi
backup_dir=${BACKUP_DIR:-/var/backups/syncro1}
timestamp=$(date -u +%Y%m%dT%H%M%SZ)
install -d -m 0700 "$backup_dir"
umask 077
mysqldump --single-transaction --routines --triggers \
	-h "${DB_HOST:?DB_HOST is required}" -P "${DB_PORT:-3306}" \
	-u "${DB_USER:?DB_USER is required}" -p"${DB_PASSWORD:?DB_PASSWORD is required}" \
	"${DB_NAME:?DB_NAME is required}" | gzip -9 > "$backup_dir/mantis-$timestamp.sql.gz"
echo "Created $backup_dir/mantis-$timestamp.sql.gz"
