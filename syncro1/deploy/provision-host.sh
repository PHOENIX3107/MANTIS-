#!/bin/sh
set -eu

if [ "$(id -u)" -ne 0 ]; then
	echo 'Run provision-host.sh as root.' >&2
	exit 1
fi

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
	nginx certbot python3-certbot-nginx awscli jq mysql-client \
	php8.3-fpm php8.3-mysql php8.3-mbstring php8.3-intl php8.3-gd \
	php8.3-xml php8.3-zip php8.3-curl php8.3-opcache

install -d -o www-data -g www-data -m 0750 /var/lib/syncro1/uploads
install -d -o www-data -g www-data -m 0750 /var/log/syncro1
install -d -o root -g root -m 0750 /etc/syncro1

if [ ! -f /etc/syncro1/syncro1.env ]; then
	install -o root -g root -m 0600 /dev/null /etc/syncro1/syncro1.env
	echo 'Populate /etc/syncro1/syncro1.env from SSM/Secrets Manager before starting the app.'
fi

install -o root -g root -m 0644 syncro1/deploy/nginx.conf /etc/nginx/nginx.conf
rm -f /etc/php/8.3/fpm/pool.d/www.conf
install -o root -g root -m 0644 syncro1/deploy/php-fpm-pool.conf /etc/php/8.3/fpm/pool.d/syncro1.conf
max_upload_mb=${MAX_UPLOAD_MB:-20}
cookie_secure=${COOKIE_SECURE:-1}
php_ini=/etc/php/8.3/fpm/conf.d/99-syncro1.ini
sed -e "s/\${MAX_UPLOAD_MB}/$max_upload_mb/g" -e "s/\${COOKIE_SECURE}/$cookie_secure/g" \
	syncro1/deploy/php.ini.template > "$php_ini"
chmod 0644 "$php_ini"

install -d -m 0755 /etc/nginx/templates
php_fpm_upstream=${PHP_FPM_UPSTREAM:-127.0.0.1:9000}
sed -e "s/\${MAX_UPLOAD_MB}/$max_upload_mb/g" -e "s/\${PHP_FPM_UPSTREAM}/$php_fpm_upstream/g" \
	syncro1/deploy/nginx-vhost.conf.template > /etc/nginx/sites-available/syncro1.conf
ln -sfn /etc/nginx/sites-available/syncro1.conf /etc/nginx/sites-enabled/syncro1.conf
rm -f /etc/nginx/sites-enabled/default

install -m 0644 syncro1/deploy/systemd/syncro1-email-queue.service /etc/systemd/system/
install -m 0644 syncro1/deploy/systemd/syncro1-email-queue.timer /etc/systemd/system/
install -m 0644 syncro1/deploy/systemd/syncro1-backup.service /etc/systemd/system/
install -m 0644 syncro1/deploy/systemd/syncro1-backup.timer /etc/systemd/system/

systemctl enable nginx php8.3-fpm
systemctl daemon-reload
systemctl enable syncro1-email-queue.timer syncro1-backup.timer
echo 'Host packages and shared configuration installed. Deploy a release before enabling services.'
