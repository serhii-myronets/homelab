# Decisions

Why things are the way they are, so they do not get relitigated.

## Portainer deploys the stacks, but nothing deploys Portainer

Four stacks come straight from this repository through Portainer's GitOps.
Portainer itself is brought up by `bootstrap.sh` with plain compose, because a
self-redeploy that fails halfway takes down the UI that manages everything
else. The manual path doubles as the bootstrap, so it is exercised rather than
theoretical.

Its stack definitions live in Portainer's database rather than in git — but
that database is inside `docker/data`, which is backed up, so they survive a
rebuild and only need a **Deploy** click each.

## OpenMediaVault stays, for now

It earns very little: two SMB shares and a disk mount, with only the five base
packages installed and no plugins. The equivalent by hand is about twenty lines
of `fstab` and `smb.conf`.

What made it actively harmful was its Docker Compose plugin, which generated
files marked *do not edit* and kept a second, drifting copy of every stack.
That is gone. What remains does not touch git, so the cost of keeping it is now
close to zero, while migrating off it is a weekend with a mounted 1.7 TB disk
at stake.

Its configuration lives entirely in `/etc/openmediavault/config.xml`, which the
backup carries. Restoring that one file brings back shares, mounts, SMART,
users and network.

## restic, not OMV's rsync

OMV cannot back up its own configuration: rsync jobs operate on shared folders,
and `config.xml` is in `/etc`, out of their reach, with no backup plugin
installed. Something outside OMV is therefore required no matter what — and
once one such thing exists, it may as well cover the rest.

Beyond that, rsync mirrors while restic snapshots. A file corrupted or deleted
a week ago is gone from a mirror and still present in a snapshot.

## TrueNAS was ruled out on hardware

Its minimum is 8 GB of RAM against the NAS's 7.6 GB, and it does not recommend
ZFS on a single disk without redundancy, which is exactly the situation. It is
also a larger appliance than OMV with a less accessible configuration, so it
moves away from keeping things in git rather than towards it.

## Open: fold everything into the Proxmox box

The idea is to move the stacks and the disk onto `proxmox`, and switch the NAS
off entirely.

**What argues for it.** The hardware is not close — an i9-12900HK with 62 GB
against a Celeron J4125 with 7.6 GB, and Iris Xe for Jellyfin instead of UHD
600. Terraform already describes infrastructure on that box, so a container
definition would land in git and OMV would disappear along with the last piece
that cannot. Backups would become `vzdump` of a whole container, which is far
simpler than restoring `config.xml`, mounting a disk and redeploying stacks.
The disk has a free SATA controller to move into, and `enp3s0` is free, so the
container could sit on `192.168.8.0/24` without re-addressing anything.

**What argues against it.** That box is the laboratory — clusters get destroyed
and rebuilt on it through Terraform. The NAS's real value is that it is boring:
nothing touches it, so it keeps working. Consolidating puts the media, the
torrents and the shares one stray `terraform destroy` away from the
experiments. Guest RAM is also already over-allocated on paper, though actual
use leaves room.

**What would make it safe.** Separate Terraform state for the production
container from the Talos playground, so a destroy in one cannot reach the
other. With that discipline the risk is ordinary; without it the whole point of
a separate box is lost.

**If it happens, do not carry OMV across.** In an LXC it fights the container
boundary over disks, SMART and mounts — the same class of problem as the
compose plugin, with another layer on top. A plain Debian container running
only Samba, defined in Terraform, is both smaller and more in keeping with
where everything else already lives.

## Open: nothing is off-box

Both restic repositories are inside the NAS, so fire, theft or a dead power
supply takes the configuration with the data. Closing it is one more entry in
`backup.sh` pointing at `sftp:` on the Proxmox box. This is worth more than any
of the migrations above and has not been done.
