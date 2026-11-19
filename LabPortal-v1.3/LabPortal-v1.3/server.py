#!/usr/bin/env python3
"""LabPortal 1.3 — standalone training portal, accepts TEST-0000 style codes only."""
import json, os, re, ssl, threading
from datetime import datetime, timezone
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from pathlib import Path
from urllib.parse import parse_qs, urlsplit

ROOT = Path(__file__).resolve().parent
LOG = ROOT / 'demo-events.jsonl'
PAGE = (ROOT / 'web' / 'index.html').read_bytes()
HOST = os.environ.get('LAB_HOST', '0.0.0.0')
HTTP_PORT = int(os.environ.get('LAB_HTTP_PORT', '18765'))
HTTPS_PORT = int(os.environ.get('LAB_HTTPS_PORT', '18443'))
LOCK = threading.Lock()

class Handler(BaseHTTPRequestHandler):
    def reply(self, status, body, mime='text/html; charset=utf-8'):
        self.send_response(status)
        self.send_header('Content-Type', mime)
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Cache-Control', 'no-store')
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path = urlsplit(self.path).path
        if path in ('/', '/index.html'):
            self.reply(200, PAGE)
        elif path == '/api/captive':
            # RFC 8908 discovery endpoint. Self-signed TLS is for local tests only;
            # real clients generally reject the API without a trusted certificate.
            payload = {'captive': True, 'user-portal-url': f"http://{os.environ.get('LAB_IP','10.42.0.1')}:{HTTP_PORT}/"}
            self.reply(200, json.dumps(payload).encode(), 'application/captive+json')
        elif path == '/health':
            self.reply(200, json.dumps({'status':'ok','version':'1.3'}).encode(), 'application/json')
        else:
            self.reply(404, b'Not found', 'text/plain')

    def do_POST(self):
        if urlsplit(self.path).path != '/demo':
            return self.reply(404, b'Not found', 'text/plain')
        try:
            size = int(self.headers.get('Content-Length', '0'))
        except ValueError:
            return self.reply(400, b'Invalid Content-Length', 'text/plain')
        if size < 1 or size > 256:
            return self.reply(413, b'Invalid request size', 'text/plain')
        raw = self.rfile.read(size).decode('utf-8', 'replace')
        code = parse_qs(raw).get('demo_code', [''])[0].strip()
        if not re.fullmatch(r'TEST-[0-9]{4}', code):
            result = {'ok':False,'message':'Only TEST-0000 through TEST-9999 are permitted. Do not enter passwords.'}
            return self.reply(400, json.dumps(result).encode(), 'application/json')
        event = {'time_utc':datetime.now(timezone.utc).isoformat(), 'demo_code':code, 'result':'received'}
        with LOCK:
            with LOG.open('a', encoding='utf-8') as handle:
                handle.write(json.dumps(event) + '\n')
        print('[LAB EVENT]', json.dumps(event), flush=True)
        result = {'ok':True,'message':'Demo code received and logged.', 'code':code}
        self.reply(200, json.dumps(result).encode(), 'application/json')

    def log_message(self, fmt, *args):
        print('[WEB]', fmt % args, flush=True)

def serve_http():
    server = ThreadingHTTPServer((HOST, HTTP_PORT), Handler)
    print(f'[HTTP]  listening on {HOST}:{HTTP_PORT}', flush=True)
    server.serve_forever()

def serve_https():
    cert = ROOT / 'certs' / 'server.crt'
    key = ROOT / 'certs' / 'server.key'
    if not (cert.exists() and key.exists()):
        print('[HTTPS] no certificate found: HTTP mode still runs', flush=True)
        return
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(str(cert), str(key))
    server = ThreadingHTTPServer((HOST, HTTPS_PORT), Handler)
    server.socket = context.wrap_socket(server.socket, server_side=True)
    print(f'[HTTPS] listening on {HOST}:{HTTPS_PORT} (self-signed certificate)', flush=True)
    server.serve_forever()

if __name__ == '__main__':
    print('[LabPortal v1.3] Training-only; never submit passwords or private data.', flush=True)
    print(f'[LOG] {LOG}', flush=True)
    thread = threading.Thread(target=serve_https, daemon=True)
    thread.start()
    serve_http()
