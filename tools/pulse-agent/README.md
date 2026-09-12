# Pulse host agent

Pulse itself is the `core/pulse` Portainer stack. This installer enrols a host
in that server; it is run by hand because neither core's host services nor
Proxmox are reconciled by Portainer.

Create an agent token in **Pulse → Settings → Infrastructure**, then run:

```sh
sudo ./install.sh http://192.168.8.100:7655 TOKEN
sudo ./install.sh http://192.168.8.100:7655 TOKEN --enable-proxmox
```

The first command is for core and auto-detects Docker. The second is for the
Proxmox host and enables its local telemetry. The token is a secret: pass it
at the prompt or command line, never add it to this repository.

```sh
systemctl status pulse-agent
journalctl -u pulse-agent -n 50
```
