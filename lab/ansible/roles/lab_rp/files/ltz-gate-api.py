#!/usr/bin/env python3
from http.server import BaseHTTPRequestHandler, HTTPServer
import json, time, os

STATUS = os.environ.get("LTZ_STATUS_CACHE", "/var/cache/ltz-gate/status.json")
MAX_AGE = int(os.environ.get("LTZ_MAX_AGE", "86400"))
PORT = int(os.environ.get("LTZ_GATE_PORT", "8089"))

class H(BaseHTTPRequestHandler):
    def _status(self):
        try:
            with open(STATUS) as f:
                return json.load(f)
        except Exception:
            return None

    def do_GET(self):
        if self.path == "/healthz":
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"ok")
            return
        if self.path == "/gate":
            st = self._status()
            now = int(time.time())
            ok = bool(st) and st.get("tpm_cba_cert") is True and (now - int(st.get("ts", 0))) < MAX_AGE
            body = json.dumps({"allowed": ok, "status": st}).encode()
            self.send_response(200 if ok else 403)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(body)
            return
        self.send_response(404)
        self.end_headers()

    def do_PUT(self):
        if self.path != "/status":
            self.send_response(404)
            self.end_headers()
            return
        n = int(self.headers.get("Content-Length", 0))
        data = self.rfile.read(n)
        os.makedirs(os.path.dirname(STATUS), exist_ok=True)
        with open(STATUS, "wb") as f:
            f.write(data)
        self.send_response(204)
        self.end_headers()

    def log_message(self, *args):
        return

if __name__ == "__main__":
    HTTPServer(("0.0.0.0", PORT), H).serve_forever()
