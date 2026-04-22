#!/usr/bin/env bash
# Discovers live hosts via fping and adds them as ping-only devices to LibreNMS.
# Skips devices that are already monitored (SNMP or ping-only).
# Runs on the host, executes commands inside the librenms container.
set -uo pipefail

CONTAINER="librenms"
NETWORKS=("10.7.5.0/24")

for net in "${NETWORKS[@]}"; do
  echo "Ping scanning ${net}..."
  docker exec "$CONTAINER" bash -c "
    fping -g -a ${net} 2>/dev/null | while read -r ip; do
      lnms device:add \"\$ip\" --ping-only 2>/dev/null && echo \"  Added \$ip (ping-only)\" || true
    done
  "
done
