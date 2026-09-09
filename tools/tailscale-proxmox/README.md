# Tailscale subnet router on Proxmox

Installs Tailscale on the Proxmox host and advertises the homelab VLAN
`10.1.1.0/24` to the tailnet. Run this by hand on Proxmox; it is not a
Portainer stack.

## Run

Copy the repository to the Proxmox host, then run as root:

```bash
./install.sh
```

The script opens the normal Tailscale login flow. For unattended provisioning,
provide a short-lived, tagged auth key through the environment; never commit it:

```bash
TAILSCALE_AUTH_KEY='tskey-...' ./install.sh
```

After login, approve the advertised `10.1.1.0/24` route in the Tailscale admin
console. Keep `--accept-dns=false`: Proxmox should continue using its existing
DNS configuration.

The installer enables IP forwarding and uses Tailscale's default SNAT for
subnet routes. Do not advertise an exit node or the `192.168.8.0/24` LAN here;
Flint 2 advertises that LAN separately.

## Remove

The script does not remove anything. To disconnect the host later, run:

```bash
tailscale logout
```

Then remove the old machine and route in the Tailscale admin console.
