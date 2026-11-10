#!/usr/bin/env python3
"""Sign the cluster in to IBKR's hosted MCP server, read-only.

Run from the Mac: python3 ibkr-login.py <client_id>. It opens the browser at
IBKR's login with scope mcp.read only, catches the redirect on 127.0.0.1, and
writes the refresh token into the Secret `ibkr-oauth`, from which the CronJob
`ibkr-token` keeps the access token in `ibkr-token` fresh. No token reaches
the screen: only lifetimes and the granted scope are printed.

The client_id comes from a dynamic registration at
https://api.ibkr.com/oauth2/register with redirect_uri REDIRECT below and
token_endpoint_auth_method none; it is not a secret.
"""
import base64
import hashlib
import http.server
import json
import secrets
import subprocess
import sys
import time
import urllib.parse
import urllib.request

AUTHORIZE = "https://api.ibkr.com/oauth2/authorize"
TOKEN = "https://api.ibkr.com/oauth2/api/v1/token"
RESOURCE = "https://api.ibkr.com/v1/api/mcp-public"
REDIRECT = "http://127.0.0.1:53682/callback"
SCOPE = "mcp.read"
NAMESPACE = "webull-mcp"


def kubectl_apply(obj):
    subprocess.run(
        ["kubectl", "--context", "core", "apply", "-f", "-"],
        input=json.dumps(obj).encode(), check=True, stdout=subprocess.DEVNULL,
    )


def secret(name, data):
    return {
        "apiVersion": "v1", "kind": "Secret",
        "metadata": {"name": name, "namespace": NAMESPACE},
        "type": "Opaque", "stringData": data,
    }


def claims(jwt):
    try:
        body = jwt.split(".")[1]
        return json.loads(base64.urlsafe_b64decode(body + "=" * (-len(body) % 4)))
    except Exception:
        return {}


def main():
    client_id = sys.argv[1]
    verifier = secrets.token_urlsafe(64)
    challenge = base64.urlsafe_b64encode(
        hashlib.sha256(verifier.encode()).digest()).rstrip(b"=").decode()
    state = secrets.token_urlsafe(16)
    url = AUTHORIZE + "?" + urllib.parse.urlencode({
        "response_type": "code", "client_id": client_id,
        "redirect_uri": REDIRECT, "scope": SCOPE, "state": state,
        "code_challenge": challenge, "code_challenge_method": "S256",
        "resource": RESOURCE,
    })

    got = {}

    class Handler(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            q = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
            got.update({k: v[0] for k, v in q.items()})
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.end_headers()
            self.wfile.write("Done, this tab can be closed.".encode())

        def log_message(self, *args):
            pass

    server = http.server.HTTPServer(("127.0.0.1", 53682), Handler)
    server.timeout = 300
    subprocess.run(["open", url], check=True)
    print("Browser opened; waiting up to 5 minutes for the IBKR login.", flush=True)
    server.handle_request()

    if got.get("state") != state or "code" not in got:
        sys.exit(f"login failed: {got.get('error')} {got.get('error_description', '')}")

    req = urllib.request.Request(TOKEN, data=urllib.parse.urlencode({
        "grant_type": "authorization_code", "code": got["code"],
        "redirect_uri": REDIRECT, "client_id": client_id,
        "code_verifier": verifier, "resource": RESOURCE,
    }).encode(), headers={"Content-Type": "application/x-www-form-urlencoded"})
    tok = json.load(urllib.request.urlopen(req))

    kubectl_apply(secret("ibkr-oauth", {
        "client_id": client_id, "refresh_token": tok["refresh_token"]}))
    kubectl_apply(secret("ibkr-token", {
        "Authorization": "Bearer " + tok["access_token"]}))

    c = claims(tok["access_token"])
    print("granted scope:", tok.get("scope") or c.get("scope") or c.get("scp"))
    print("access token lives:", tok.get("expires_in"), "s")
    for k in ("refresh_expires_in", "refresh_token_expires_in"):
        if k in tok:
            print("refresh token lives:", tok[k], "s")
    if c:
        print("jwt aud:", c.get("aud"), "| lifetime:", c.get("exp", 0) - c.get("iat", 0), "s")
    print("other fields:", sorted(set(tok) - {"access_token", "refresh_token", "id_token"}))
    print("written:", NAMESPACE + "/ibkr-oauth,", NAMESPACE + "/ibkr-token at", time.strftime("%H:%M:%S"))


if __name__ == "__main__":
    main()
