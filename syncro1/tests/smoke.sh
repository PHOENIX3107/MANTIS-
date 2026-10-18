#!/bin/sh
set -eu

base_url=${SYNCRO1_BASE_URL:-http://localhost:8080}
curl --fail --silent "$base_url/healthz" | grep -qx 'ok'
headers=$(curl --fail --silent --show-error -D - -o /dev/null "$base_url/login_page.php")
printf '%s\n' "$headers" | grep -iq '^x-content-type-options: nosniff'
printf '%s\n' "$headers" | grep -iq '^referrer-policy:'

for blocked_path in /admin/ /config/ /.git/ /vendor/ /api/rest/ /api/soap/ /rss.php; do
	status=$(curl --silent --output /dev/null --write-out '%{http_code}' "$base_url$blocked_path")
	case "$status" in
		403|404) ;;
		*) echo "Expected $blocked_path to be blocked, got HTTP $status" >&2; exit 1 ;;
	esac
done

mailpit_url=${MAILPIT_URL:-http://localhost:8025}
curl --fail --silent "$mailpit_url/api/v1/info" | grep -q '"Messages"'
echo 'HTTP and Mailpit smoke checks passed.'
