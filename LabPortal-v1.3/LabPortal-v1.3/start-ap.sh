#!/usr/bin/env bash
# Independent open Wi-Fi test AP; no credential capture, impersonation or forced redirection.
set -euo pipefail
cd "$(dirname "$0")"
set -a; source ./config.env; set +a
command -v nmcli >/dev/null || { echo '[ERROR] nmcli missing'; exit 1; }
command -v iw >/dev/null || { echo '[ERROR] iw missing'; exit 1; }
# Recover a monitor-mode adapter left over by authorized lab tooling.
if ! iw dev "$LAB_INTERFACE" info >/dev/null 2>&1; then
  MON="${LAB_INTERFACE}mon"
  if iw dev "$MON" info >/dev/null 2>&1; then
    echo "[INFO] Found ${MON} in monitor mode. Restoring ${LAB_INTERFACE}..."
    sudo ip link set "$MON" down
    sudo iw dev "$MON" set type managed
    sudo ip link set "$MON" name "$LAB_INTERFACE"
    sudo ip link set "$LAB_INTERFACE" up
    sudo nmcli device set "$LAB_INTERFACE" managed yes || true
    sudo systemctl restart NetworkManager
    sleep 2
  fi
fi
if ! iw dev "$LAB_INTERFACE" info >/dev/null 2>&1; then
  echo "[ERROR] No ${LAB_INTERFACE}; available interfaces:"; iw dev; exit 1
fi
if ! iw list | grep -qE '^\s*\* AP$'; then
  echo '[ERROR] Adapter/driver does not advertise AP support'; exit 1
fi
sudo nmcli radio wifi on
sudo nmcli device set "$LAB_INTERFACE" managed yes
# Rebuild only this project's own profile, ensuring that no saved WPA2 security remains.
sudo nmcli connection delete 'LabPortal-v1.3' >/dev/null 2>&1 || true
sudo nmcli connection add type wifi ifname "$LAB_INTERFACE" con-name LabPortal-v1.3 ssid "$LAB_SSID"
sudo nmcli connection modify LabPortal-v1.3 \
  802-11-wireless.mode ap \
  802-11-wireless.band bg \
  ipv4.method shared \
  ipv4.addresses "${LAB_IP}/24" \
  ipv6.method disabled \
  connection.autoconnect no
# Standards-based discovery hint (DHCP option 114). It DOES NOT intercept web traffic.
# The RFC 8908 API requires a trusted HTTPS certificate; the local certificate
# provided by this demo is self-signed, so automatic popups are not guaranteed.
if [[ "${ENABLE_CAPTIVE_HINT:-1}" == "1" ]]; then
  sudo install -d -m 755 /etc/NetworkManager/dnsmasq-shared.d
  printf 'dhcp-option=114,https://%s:%s/api/captive\n' "$LAB_IP" "$LAB_HTTPS_PORT" | sudo tee /etc/NetworkManager/dnsmasq-shared.d/99-labportal-v1.3.conf >/dev/null
  echo '[INFO] DHCP option 114 hint installed for NetworkManager shared connections.'
fi
printf '[AP] Activating OPEN lab network: %s\n' "$LAB_SSID"
sudo nmcli connection up LabPortal-v1.3
printf '[OK] Open Wi-Fi: %s | Web page: http://%s:%s\n' "$LAB_SSID" "$LAB_IP" "$LAB_HTTP_PORT"
printf '[NOTE] Standards-based captive portal hint enabled (experimental).\n'
printf '[NOTE] Self-signed TLS is not trusted by phones. Auto-popup is NOT guaranteed.\n'
