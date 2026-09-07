# core

Everything deployed onto the OpenMediaVault box at `192.168.8.100`: one
directory per stack, the bootstrap, and the backup job.

Portainer deploys every stack in here straight from this repository — except
Portainer itself, which is brought up by hand with plain `docker compose`,
because a failed self-redeploy would take down the UI that manages everything
else. That manual path doubles as the bootstrap.

What each stack is and which Portainer options it needs:
[`../docs/services.yaml`](../docs/services.yaml). What will otherwise waste an
afternoon: [`../docs/traps.yaml`](../docs/traps.yaml).

## Bootstrap

```bash
git clone https://github.com/serhii-myronets/homelab.git
cd homelab
sudo ./core/bootstrap.sh
```

Creates the shared `backend` network and the data directories under
`/srv/ssd/docker/data/`, verifies the secrets, and starts Portainer. Idempotent.

Secrets are never in git. Create them under `/srv/ssd/docker/secrets/`, mode
`600`, before running — [`docs/services.yaml`](../docs/services.yaml) lists which
file holds what.

Then add the stacks in Portainer as **Stacks → Add stack → Repository**,
against this repo at `refs/heads/main`. Which stack needs which options is in
[`docs/services.yaml`](../docs/services.yaml); the two settings that will
otherwise waste an afternoon are in [`docs/traps.yaml`](../docs/traps.yaml). Read
them before creating a stack — one of the options cannot be turned on later.

## Backup

```bash
sudo ./core/backup/install.sh
```

Installs restic, initialises all three repositories, and enables a daily timer.
Prints a generated repository password once — save it off the machine, the
backups are unreadable without it.

Each disk holds the backup of what lives on the other, and a third copy goes to
the Proxmox box over sftp, so losing this machine does not lose every copy.
What each one holds, and what is deliberately not covered, is in
[`docs/backups.yaml`](../docs/backups.yaml).

The first run also generates an ssh key for the remote repository. If Proxmox
has not authorised it yet the script says so and prints the line that does —
the local backups do not wait for it.

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
cd homelab && sudo ./core/bootstrap.sh
sudo ./core/backup/install.sh
```

Portainer comes back knowing all four stacks, since its database is part of
`docker/data`. They still need a **Deploy** each — it does not redeploy stacks
on startup.

### The whole machine is gone

The Proxmox copy holds everything the two local repositories hold between them.
It needs restic and the repository password, nothing else — the repository is
plain files, so the ssh key matters only to the nightly job:

```bash
restic -r sftp:root@10.1.1.100:/var/lib/vz/backups/restic snapshots
restic -r sftp:root@10.1.1.100:/var/lib/vz/backups/restic restore latest --target /
```

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
though `core/bootstrap.sh` installs Docker if it is missing.

## Homepage

Create the stack in Portainer using the repository settings in
[`docs/services.yaml`](../docs/services.yaml). Mount the config directory with
**Enable relative path volumes** enabled at creation; leave **Additional paths**
empty.

After its first deployment, redeploy the Caddy stack from git and restart
`caddy` so its single-file bind mount picks up the updated Caddyfile. Open
`https://homepage.home`.

Edit the dashboard under `core/homepage/config/`, push, and redeploy the
Homepage stack. Use the refresh button at the bottom right of Homepage after
changing settings to regenerate the page.
