# Host metrics for Homepage

Glances 4.5.6 runs natively on core and Proxmox under systemd, as nobody,
using an isolated Python environment. This measures the hosts rather than
a container. Its API binds to the supplied LAN address on port 61208;
there is no Caddy or Cloudflare route for it. Process collection is disabled.

Run the installer as root on each target host:

```sh
bash install.sh 192.168.8.100  # on core
bash install.sh 10.1.1.100     # on Proxmox
```

The installer installs python3-venv, creates /opt/glances-homepage, and enables
and restarts glances-homepage.service. It can be run again after a rebuild.
Glances is pinned; its Python dependencies are resolved by pip at installation.

```sh
systemctl status glances-homepage
journalctl -u glances-homepage -n 50
curl http://HOST_LAN_IP:61208/api/4/cpu
```

Homepage service widgets in core/homepage/config/services.yaml query both
hosts server-side. Full Core and Proxmox graph groups sit at the end of the
page on both Local and Public tabs. Each contains CPU, RAM, filesystem usage
and CPU package temperature. Core shows its data filesystem; Proxmox shows
its root filesystem, not LVM-thin VM storage. The header has no metrics.
Graphs accumulate samples while the page is open, rather than storing history.
Metrics are visible to viewers of Homepage, including through its public URL.

Verified the Glances endpoints and Homepage proxy responses after installation.
