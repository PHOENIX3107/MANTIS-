#!/bin/sh
set -eu

release_root=${1:?usage: render-config.sh RELEASE_ROOT}
template_root="$release_root/syncro1/config"
config_root="$release_root/config"

if [ ! -d "$template_root" ]; then
	echo "Missing SYNCRO1 config templates in $template_root" >&2
	exit 1
fi

if [ "${SYNCRO1_ENV:-production}" = production ]; then
	for required_name in ADMIN_EMAIL ADMIN_INITIAL_PASSWORD CRYPTO_MASTER_SALT DB_HOST DB_NAME DB_USER DB_PASSWORD SMTP_HOST SMTP_PORT MAIL_FROM APP_DOMAIN APP_URL; do
		required_value=$(printenv "$required_name" 2>/dev/null || true)
		if [ -z "$required_value" ]; then
			echo "Missing required production environment variable: $required_name" >&2
			exit 1
		fi
	done
fi

install -d -m 0750 "$config_root"
install -m 0640 "$template_root/config_inc.php" "$config_root/config_inc.php"
install -m 0640 "$template_root/custom_constants_inc.php" "$config_root/custom_constants_inc.php"
install -m 0640 "$template_root/custom_strings_inc.php" "$config_root/custom_strings_inc.php"
echo "Rendered SYNCRO1 configuration in $config_root"
