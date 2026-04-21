#!/usr/bin/env bash
set -euo pipefail

CONTAINER="librenms"
APP_DIR="/opt/monitoring"
MARKER="${APP_DIR}/.bootstrapped"

if [ -f "$MARKER" ]; then
  echo "Bootstrap already completed. Remove ${MARKER} to re-run."
  exit 0
fi

echo "=== LibreNMS Bootstrap ==="
echo "Waiting for LibreNMS to be fully initialized..."

for i in $(seq 1 30); do
  if docker exec "$CONTAINER" lnms --version >/dev/null 2>&1; then
    break
  fi
  echo "  Attempt $i/30 — waiting 10s..."
  sleep 10
done

run_lnms() {
  docker exec "$CONTAINER" lnms "$@"
}

# --- SNMP community ---
echo ""
echo ">> Configuring SNMP community..."
COMMUNITY="${SNMP_COMMUNITY:-public}"
run_lnms config:set snmp.community.0 "$COMMUNITY"

# --- Auto-discovery networks ---
echo ""
echo ">> Adding auto-discovery networks..."
run_lnms config:set nets.0 "10.7.5.0/24"
run_lnms config:set nets.1 "10.0.0.0/24"

echo ">> Enabling auto-discovery..."
run_lnms config:set discovery_by_ip true
run_lnms config:set autodiscovery.nets-exclude.0 "127.0.0.0/8"

# --- Poller settings ---
echo ""
echo ">> Configuring poller..."
run_lnms config:set rrd.step 300
run_lnms config:set snmp.timeout 5
run_lnms config:set snmp.retries 2
run_lnms config:set ping_rrd true

# --- Enable key features ---
echo ""
echo ">> Enabling features..."
run_lnms config:set enable_syslog true
run_lnms config:set enable_inventory true

# --- Device groups ---
echo ""
echo ">> Creating device groups..."

create_group() {
  local name="$1"
  local desc="$2"
  local pattern="$3"
  docker exec "$CONTAINER" php /opt/librenms/artisan devicegroup:add \
    --name="$name" \
    --desc="$desc" \
    --type=dynamic \
    --rules="$pattern" 2>/dev/null || echo "  Group '$name' may already exist"
}

create_group "Infrastruktur" "Netværksinfrastruktur (routere, switche, AP)" \
  '[{"field":"devices.type","op":"=","value":"network"}]'

create_group "Kamera" "EyeTrack kamerasystem og NVR" \
  '[{"field":"devices.purpose","op":"contains","value":"camera"}]'

echo "  Note: Tilmelding and Vandingsanlæg groups can be created in the web UI"
echo "  after devices are discovered and categorized."

# --- Alert rules ---
echo ""
echo ">> Configuring default alert rules..."
run_lnms config:set alert.default_mail false

# --- Mark bootstrap complete ---
touch "$MARKER"

echo ""
echo "=== Bootstrap complete ==="
echo ""
echo "Next steps:"
echo "  1. Open LibreNMS: ${LIBRENMS_BASE_URL:-http://localhost:8000}"
echo "  2. Create admin user in web UI on first visit"
echo "  3. Devices on 10.7.5.0/24 and 10.0.0.0/24 will auto-discover"
echo "  4. Add any ping-only devices manually via web UI"
echo "  5. Configure Slack alerts under Alerts -> Alert Transports"
echo ""
