#!/usr/bin/env bash
set -euo pipefail
sudo nmcli connection down LabPortal-v1.3 || true
sudo rm -f /etc/NetworkManager/dnsmasq-shared.d/99-labportal-v1.3.conf
echo '[OK] Lab AP stopped and DHCP hint removed.'
