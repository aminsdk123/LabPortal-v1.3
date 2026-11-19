#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
set -a; source ./config.env; set +a
printf '\n=== NetworkManager ===\n'; nmcli device status 2>/dev/null || true
printf '\n=== Wi-Fi ===\n'; iw dev 2>/dev/null || true
printf '\n=== HTTP endpoint ===\n'; curl --max-time 3 -sSi "http://127.0.0.1:${LAB_HTTP_PORT}/health" || true
printf '\n=== HTTPS endpoint ===\n'; curl --max-time 3 -ksSi "https://127.0.0.1:${LAB_HTTPS_PORT}/health" || true
printf '\n=== listeners ===\n'; ss -lntp 2>/dev/null | grep -E ":(${LAB_HTTP_PORT}|${LAB_HTTPS_PORT})\\b" || true

printf '\n=== Captive API test (local only) ===\n'; curl --max-time 3 -ksSi "https://127.0.0.1:${LAB_HTTPS_PORT}/api/captive" || true
printf '\n=== DHCP option 114 local config ===\n'; test -f /etc/NetworkManager/dnsmasq-shared.d/99-labportal-v1.3.conf && echo 'present' || echo 'not installed'
