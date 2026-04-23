#!/usr/bin/env bash
# Syncs device and client names from UniFi controller to /etc/hosts
# and updates LibreNMS display names via the database.
# Runs on the host VM, reads API key from /opt/monitoring/.env.
set -uo pipefail

APP_DIR="/opt/monitoring"
UNIFI_HOST="https://10.0.0.1"
HOSTS_FILE="/etc/hosts"
BEGIN_MARKER="# BEGIN UNIFI MANAGED"
END_MARKER="# END UNIFI MANAGED"

# shellcheck source=/dev/null
if [[ -f "${APP_DIR}/.env" ]]; then
  source "${APP_DIR}/.env"
fi

if [[ -z "${UNIFI_API_KEY:-}" ]]; then
  echo "Error: UNIFI_API_KEY not set in ${APP_DIR}/.env"
  exit 1
fi

API_HEADER="X-API-KEY: ${UNIFI_API_KEY}"
API_BASE="${UNIFI_HOST}/proxy/network/api/s/default"

sanitize() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9.-' | tr -s '-' | sed 's/^-//;s/-$//'
}

echo "Fetching adopted devices..."
devices=$(curl -sSk -H "${API_HEADER}" "${API_BASE}/stat/device" 2>/dev/null)
if [[ -z "$devices" ]]; then
  echo "Error: Failed to fetch devices from UniFi controller"
  exit 1
fi

echo "Fetching known clients..."
clients=$(curl -sSk -H "${API_HEADER}" "${API_BASE}/rest/user" 2>/dev/null) || true

echo "Fetching active clients..."
active=$(curl -sSk -H "${API_HEADER}" "${API_BASE}/stat/sta" 2>/dev/null) || true

entries=""

device_entries=$(echo "$devices" | jq -r '.data[] | select(.name != null and .name != "" and .ip != null) | "\(.ip) \(.name)"' 2>/dev/null) || true
entries="$device_entries"

if [[ -n "$clients" ]]; then
  client_entries=$(echo "$clients" | jq -r '.data[] | select(.name != null and .name != "" and .fixed_ip != null and .fixed_ip != "") | "\(.fixed_ip) \(.name)"' 2>/dev/null) || true
  entries=$(printf '%s\n%s' "$entries" "$client_entries")
fi

if [[ -n "$active" ]]; then
  active_entries=$(echo "$active" | jq -r '.data[] | select(.ip != null and .name != null and .name != "") | "\(.ip) \(.name)"' 2>/dev/null) || true
  entries=$(printf '%s\n%s' "$entries" "$active_entries")
fi

entries=$(echo "$entries" | grep -v '^$' | while IFS=' ' read -r ip name; do
  sname=$(sanitize "$name")
  if [[ -n "$sname" && -n "$ip" ]]; then
    echo "$ip $sname"
  fi
done | awk '!seen[$1]++' | grep -E '^(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.)' | sort -t. -k1,1n -k2,2n -k3,3n -k4,4n)

count=$(echo "$entries" | grep -c '.' || true)

if [[ $count -eq 0 ]]; then
  echo "Warning: No entries found, skipping /etc/hosts update"
  exit 0
fi

tmpfile=$(mktemp)
if grep -q "$BEGIN_MARKER" "$HOSTS_FILE"; then
  sed "/$BEGIN_MARKER/,/$END_MARKER/d" "$HOSTS_FILE" > "$tmpfile"
else
  cp "$HOSTS_FILE" "$tmpfile"
fi

{
  echo "$BEGIN_MARKER"
  echo "$entries"
  echo "$END_MARKER"
} >> "$tmpfile"

cp "$tmpfile" "$HOSTS_FILE"
rm -f "$tmpfile"

echo "Updated /etc/hosts with ${count} UniFi entries"

echo "Updating LibreNMS display names..."
json_mapping=$(echo "$entries" | awk '{printf "%s\"%s\":\"%s\"", (NR>1?",":""), $1, $2}')
json_mapping="{${json_mapping}}"

docker cp "${APP_DIR}/scripts/update-display-names.php" librenms:/tmp/update-display-names.php
result=$(echo "$json_mapping" | docker exec -i librenms php /tmp/update-display-names.php)
echo "LibreNMS: ${result}"
