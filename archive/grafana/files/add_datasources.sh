#!/bin/bash
#set -e

# ADD INFLUXDB DATASOURCE
curl -s -H "Content-Type: application/json" \
    -XPOST http://${GF_SECURITY_ADMIN_USER}:${GF_SECURITY_ADMIN_PASSWORD}@localhost:3000/api/datasources \
    -d @- <<EOF
{
    "name": "influxdb",
    "type": "influxdb",
    "access": "proxy",
    "url": "http://influxdb:8086",
    "database": "telegraf",
    "user":"telegraf",
    "password":"thispassworddoesntreallymatter",
    "basicAuth":false
}
EOF

## ADD PROMETHEUS DATASOURCE
curl -s -H "Content-Type: application/json" \
    -XPOST http://${GF_SECURITY_ADMIN_USER}:${GF_SECURITY_ADMIN_PASSWORD}@localhost:3000/api/datasources \
    -d @- <<EOF
{
    "name": "prometheus",
    "type": "prometheus",
    "access": "proxy",
    "url": "http://prometheus:9090"
}
EOF

# to ensure we exit 0 and not kill the container
exit 0