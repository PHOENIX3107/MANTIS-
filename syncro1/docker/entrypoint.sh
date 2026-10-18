#!/bin/sh
set -eu

app_root=/var/www/mantis
mkdir -p /var/lib/syncro1/uploads /var/log/syncro1
chown -R www-data:www-data /var/lib/syncro1 /var/log/syncro1
touch /var/log/syncro1/mantis.log
chown www-data:www-data /var/log/syncro1/mantis.log

t_max_upload_mb=${MAX_UPLOAD_MB:-20}
t_cookie_secure=${COOKIE_SECURE:-0}
case "$t_max_upload_mb" in
	*[!0-9]*|'') echo 'MAX_UPLOAD_MB must be a positive integer' >&2; exit 1 ;;
esac
case "$t_cookie_secure" in
	0|1) ;;
	*) echo 'COOKIE_SECURE must be 0 or 1' >&2; exit 1 ;;
esac
sed -e "s/\${MAX_UPLOAD_MB}/$t_max_upload_mb/g" \
	-e "s/\${COOKIE_SECURE}/$t_cookie_secure/g" \
	/usr/local/etc/php/conf.d/zz-syncro1.ini.template \
	> /usr/local/etc/php/conf.d/zz-syncro1.ini

i=0
# shellcheck disable=SC2016
while ! php -r '$s=@fsockopen(getenv("DB_HOST") ?: "mysql", (int)(getenv("DB_PORT") ?: 3306), $e, $m, 2); if ($s) { fclose($s); exit(0); } exit(1);'; do
	i=$((i + 1))
	if [ "$i" -ge 60 ]; then
		echo 'Database did not become reachable'
		exit 1
	fi
	sleep 2
done

if [ ! -f "$app_root/syncro1/.installed" ]; then
	if ! php "$app_root/syncro1/scripts/install-headless"; then
		echo 'Headless schema installation failed'
		exit 1
	fi
	php "$app_root/syncro1/scripts/bootstrap"
	"$app_root/syncro1/scripts/post-install-lockdown" "$app_root"
	touch "$app_root/syncro1/.installed"
fi

exec "$@"
