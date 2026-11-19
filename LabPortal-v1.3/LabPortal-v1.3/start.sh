#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
set -a; source ./config.env; set +a
command -v python3 >/dev/null || { echo '[ERROR] python3 required'; exit 1; }
command -v openssl >/dev/null || { echo '[ERROR] openssl required'; exit 1; }
mkdir -p certs
if [[ ! -s certs/server.key || ! -s certs/server.crt ]]; then
  echo '[SETUP] Generating local testing certificate...'
  openssl req -x509 -nodes -newkey rsa:2048 -days 60 \
    -keyout certs/server.key -out certs/server.crt \
    -subj '/CN=LabPortal Local Demo' \
    -addext "subjectAltName=DNS:localhost,IP:127.0.0.1,IP:${LAB_IP}" >/dev/null 2>&1
  chmod 600 certs/server.key
fi
printf '\nLabPortal v1.3 | HTTP: http://127.0.0.1:%s | HTTPS: https://127.0.0.1:%s\n' "$LAB_HTTP_PORT" "$LAB_HTTPS_PORT"
printf 'Wi-Fi lab clients (if AP active): http://%s:%s\n' "$LAB_IP" "$LAB_HTTP_PORT"
printf 'HTTPS uses a self-signed certificate, so other devices will show a warning.\n'
exec python3 server.py
