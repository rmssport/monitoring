# SNMP Troubleshooting

The monitoring VM has `snmpwalk` and other SNMP tools installed for testing and debugging device connectivity.

## Quick test: is SNMP working on a device?

```bash
# Basic SNMP v2c query — returns the device description
snmpwalk -v2c -c public 10.7.5.1 sysDescr.0

# If it returns something like:
#   SNMPv2-MIB::sysDescr.0 = STRING: EdgeOS v2.0.9...
# then SNMP is working on that device.
```

Replace `public` with your SNMP community string if different.

## Common snmpwalk examples

### Device identity

```bash
# System description (hardware/software info)
snmpwalk -v2c -c public 10.7.5.1 sysDescr

# Hostname
snmpwalk -v2c -c public 10.7.5.1 sysName

# Uptime
snmpwalk -v2c -c public 10.7.5.1 sysUpTime
```

### Network interfaces

```bash
# List all interface names
snmpwalk -v2c -c public 10.7.5.6 ifDescr

# Interface status (up/down)
snmpwalk -v2c -c public 10.7.5.6 ifOperStatus

# Interface speeds
snmpwalk -v2c -c public 10.7.5.6 ifSpeed

# Bytes in/out per interface (for bandwidth calculation)
snmpwalk -v2c -c public 10.7.5.6 ifInOctets
snmpwalk -v2c -c public 10.7.5.6 ifOutOctets

# Interface errors (packet loss indicator)
snmpwalk -v2c -c public 10.7.5.6 ifInErrors
snmpwalk -v2c -c public 10.7.5.6 ifOutErrors

# Discarded packets
snmpwalk -v2c -c public 10.7.5.6 ifInDiscards
snmpwalk -v2c -c public 10.7.5.6 ifOutDiscards
```

### Walk everything (verbose)

```bash
# Full SNMP tree — can be very long, useful for discovering what a device exposes
snmpwalk -v2c -c public 10.7.5.6

# Limit to a specific MIB subtree
snmpwalk -v2c -c public 10.7.5.6 .1.3.6.1.2.1.2   # IF-MIB (interfaces)
snmpwalk -v2c -c public 10.7.5.6 .1.3.6.1.2.1.1   # System MIB
```

## Calculating bandwidth from snmpwalk

SNMP counters are cumulative. To get throughput, poll twice and calculate:

```
bps = ((poll2_octets - poll1_octets) * 8) / seconds_between_polls
```

Example:
```bash
# Poll 1
snmpget -v2c -c public 10.7.5.6 ifInOctets.1
# IF-MIB::ifInOctets.1 = Counter32: 1000000

# Wait 60 seconds, poll again
snmpget -v2c -c public 10.7.5.6 ifInOctets.1
# IF-MIB::ifInOctets.1 = Counter32: 1500000

# Throughput = (1500000 - 1000000) * 8 / 60 = 66,666 bps ≈ 67 kbps
```

LibreNMS does this automatically — these manual checks are just for troubleshooting.

## Troubleshooting

### "Timeout: No Response"

- Device SNMP is disabled or community string is wrong
- Firewall blocking UDP port 161
- Device is on a different subnet and not routable

```bash
# Verify basic connectivity first
ping 10.7.5.6

# Try with a longer timeout (default is 1 second)
snmpwalk -v2c -c public -t 5 10.7.5.6 sysDescr
```

### "No Such Object available"

The OID you requested doesn't exist on this device. Try walking the full tree to see what's available:

```bash
snmpwalk -v2c -c public 10.7.5.6 | head -50
```

### SNMPv3

If a device uses SNMPv3 instead of v2c:

```bash
snmpwalk -v3 -u myuser -l authPriv -a SHA -A "authpass" -x AES -X "privpass" 10.7.5.6 sysDescr
```
