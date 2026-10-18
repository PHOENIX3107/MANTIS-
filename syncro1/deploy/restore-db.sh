#!/bin/sh
set -eu

backup_file=${1:?usage: restore-db.sh BACKUP.sql.gz}
if [ "${RESTORE_CONFIRM:-}" != YES ]; then
	echo 'This is destructive. Re-run with RESTORE_CONFIRM=YES.' >&2
	exit 1
fi
if [ -f /etc/syncro1/syncro1.env ]; then
	# shellcheck disable=SC1091
	. /etc/syncro1/syncro1.env
fi
gzip -dc "$backup_file" | mysql \
	-h "${DB_HOST:?DB_HOST is required}" -P "${DB_PORT:-3306}" \
	-u "${DB_USER:?DB_USER is required}" -p"${DB_PASSWORD:?DB_PASSWORD is required}" \
	"${DB_NAME:?DB_NAME is required}"
echo "Restored $backup_file into ${DB_NAME}."
