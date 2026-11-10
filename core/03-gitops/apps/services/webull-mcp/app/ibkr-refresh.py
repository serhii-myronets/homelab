"""Trade the refresh token in Secret ibkr-oauth for a fresh access token in
Secret ibkr-token, where the gateway reads it. If IBKR hands back a new
refresh token, it replaces the old one. Talks to the API server directly, so
the image needs nothing beyond Python."""
import base64
import json
import ssl
import urllib.parse
import urllib.request

TOKEN = "https://api.ibkr.com/oauth2/api/v1/token"
RESOURCE = "https://api.ibkr.com/v1/api/mcp-public"
SA = "/var/run/secrets/kubernetes.io/serviceaccount"
API = "https://kubernetes.default.svc"

ns = open(f"{SA}/namespace").read().strip()
auth = {"Authorization": "Bearer " + open(f"{SA}/token").read().strip()}
ctx = ssl.create_default_context(cafile=f"{SA}/ca.crt")


def kube(method, name, body=None):
    req = urllib.request.Request(
        f"{API}/api/v1/namespaces/{ns}/secrets/{name}", method=method,
        data=json.dumps(body).encode() if body else None,
        headers={**auth, "Content-Type": "application/merge-patch+json"})
    return json.load(urllib.request.urlopen(req, context=ctx))


oauth = {k: base64.b64decode(v).decode() for k, v in kube("GET", "ibkr-oauth")["data"].items()}
tok = json.load(urllib.request.urlopen(urllib.request.Request(TOKEN, data=urllib.parse.urlencode({
    "grant_type": "refresh_token", "refresh_token": oauth["refresh_token"],
    "client_id": oauth["client_id"], "resource": RESOURCE,
}).encode(), headers={"Content-Type": "application/x-www-form-urlencoded"})))

# The new refresh token is saved first: if the access token write failed after
# a rotation, the next run still holds a refresh token IBKR accepts.
if tok.get("refresh_token") and tok["refresh_token"] != oauth["refresh_token"]:
    kube("PATCH", "ibkr-oauth", {"stringData": {"refresh_token": tok["refresh_token"]}})
kube("PATCH", "ibkr-token", {"stringData": {"Authorization": "Bearer " + tok["access_token"]}})
print("refreshed; access token lives", tok.get("expires_in"), "s; rotated:",
      tok.get("refresh_token") not in (None, oauth["refresh_token"]))
