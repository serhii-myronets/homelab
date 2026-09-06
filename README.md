# homelab

Everything that runs at home: the Docker stacks on the OpenMediaVault box at
`192.168.8.100`, and the documented state of the three machines around them.

[`docs/index.yaml`](docs/index.yaml) says which file answers which question —
one YAML per machine, plus the network, the services, the backups and the
traps, each fact verified against the live host.
[`docs/decisions/`](docs/decisions/) records why the setup is shaped this way
and what is still open; [`docs/sessions/`](docs/sessions/) records how it got
there.

Portainer deploys every stack straight from this repository — except Portainer
itself, which is brought up by hand with plain `docker compose`, because a
failed self-redeploy would take down the UI that manages everything else. That
manual path doubles as the bootstrap.

## Bootstrap

```bash
git clone https://github.com/serhii-myronets/homelab.git
cd homelab
sudo ./bootstrap.sh
```

Creates the shared `backend` network and the data directories under
`/srv/ssd/docker/data/`, verifies the secrets, and starts Portainer. Idempotent.

Secrets are never in git. Create them under `/srv/ssd/docker/secrets/`, mode
`600`, before running — [`docs/services.yaml`](docs/services.yaml) lists which
file holds what.

Then add the stacks in Portainer as **Stacks → Add stack → Repository**,
against this repo at `refs/heads/main`. Which stack needs which options is in
[`docs/services.yaml`](docs/services.yaml); the two settings that will
otherwise waste an afternoon are in [`docs/traps.yaml`](docs/traps.yaml). Read
them before creating a stack — one of the options cannot be turned on later.

## Backup

```bash
sudo ./backup/install.sh
```

Installs restic, initialises both repositories, and enables a daily timer.
Prints a generated repository password once — save it off the machine, the
backups are unreadable without it.

Each disk holds the backup of what lives on the other, so losing either leaves
a copy on the survivor. What each one holds, and what is deliberately not
covered, is in [`docs/backups.yaml`](docs/backups.yaml).

```bash
export RESTIC_REPOSITORY=/var/backups/restic RESTIC_PASSWORD_FILE=/etc/restic-password
restic snapshots                          # list
restic restore latest --target /tmp/r     # restore everything
restic restore latest --target /tmp/r --include /srv/ssd/samba/scan
```

Containers keep running during a backup, so a snapshot can catch a database
mid-write. Stop the stacks first if you want a guaranteed-consistent one.

## Restore

Both directions were verified on 2026-09-06.

### The OS was reinstalled, the data disk survived

The disk mount lives in `config.xml`, which lives on that disk, so the first
step is to mount it by hand:

```bash
mkdir /mnt/d && mount /dev/sda1 /mnt/d
apt install restic
restic -r /mnt/d/backups/restic --password-file /mnt/d/backups/password \
  restore latest --target /
reboot
```

OMV reads the restored `config.xml` on boot and brings back the shares, the
disk mount, SMART, the users and the network. Nothing else needs restoring —
`docker/data` and `docker/secrets` are still sitting on the surviving disk.
Then:

```bash
git clone https://github.com/serhii-myronets/homelab.git
cd homelab && sudo ./bootstrap.sh
sudo ./backup/install.sh
```

Portainer comes back knowing all four stacks, since its database is part of
`docker/data`. They still need a **Deploy** each — it does not redeploy stacks
on startup.

### The data disk died

Fit a replacement, mount it at the same path, then restore the other
direction:

```bash
restic -r /var/backups/restic --password-file /etc/restic-password \
  restore latest --target /
chown -R 1001:1001 /srv/ssd/docker/data/torrent/flood
```

`samba/torrents` is not backed up and has to be downloaded again.

Between them, the git repo and these snapshots cover a rebuild end to end. Not
covered: SSH access — run `ssh-copy-id` again — and the installed packages,
though `bootstrap.sh` installs Docker if it is missing.
