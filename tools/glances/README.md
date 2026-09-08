# Host metrics for Homepage

Glances runs natively on core and on Proxmox, under systemd, so that it
measures the hosts rather than a container. What it exposes, where, and what
reads it is in [`docs/services.yaml`](../../docs/services.yaml) under
`host_metrics`; why it is installed this way is
[decision 0011](../../docs/decisions/0011-host-metrics-run-natively.md).

Run the installer as root on each host, passing that host's LAN address —
the API binds to it and to nothing else:

```sh
bash install.sh 192.168.8.100  # on core
bash install.sh 10.1.1.100     # on Proxmox
```

It installs python3-venv, builds /opt/glances-homepage, writes and starts
`glances-homepage.service`, and is safe to run again after a rebuild. Glances
itself is pinned; pip resolves its dependencies at installation.

Nothing reconciles this the way Portainer reconciles a stack. A host rebuilt
without running the installer keeps its Homepage cards and loses their data.

```sh
systemctl status glances-homepage
journalctl -u glances-homepage -n 50
curl http://HOST_LAN_IP:61208/api/4/cpu
```

Adding a metric to the dashboard means one more service entry in
`core/homepage/config/services.yaml`, with `chart: true` — several metrics on
one card overlap, which is in [`docs/traps.yaml`](../../docs/traps.yaml).
