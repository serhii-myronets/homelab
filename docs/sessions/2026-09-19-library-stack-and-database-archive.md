---
date: 2026-09-19
title: Archive the database, add the library stack, split downloads from it
tags: [beelink, kubernetes, openebs, volsync, cloudnative-pg, arr, storage]
---

Three pieces of work on the Beelink, in order.

## One snapshot controller, not two

The owner checked the running pods and found that the OpenEBS controller pod
carries a `snapshot-controller` container of its own, v8.2.0, beside the
`csi-snapshotter` sidecar, while the standalone chart runs v8.6.0 in
kube-system. Our values switched off only the CRDs, which says nothing about
the controller, so two controllers were watching the same objects. The chart
documents the switch itself: `lvmController.snapshotController.enabled`, with
the comment that a cluster should have one. Rendering the chart with and
without it showed a difference of seven lines and one container, so it was
disabled. Both existing VolumeSnapshots stayed ReadyToUse and the hourly
VolSync runs at 03:15 UTC finished in 17 and 15 seconds.

Rolling that Deployment left its `CSIStorageCapacity` object owned by the old
ReplicaSet, which the new provisioner could never update; it logged the
conflict every second until the object was deleted and recreated.

## The database, kept whole and switched off

Nothing used Postgres: it held 7.8 MB and no table of its own, and it had
been built for Paperless, which the owner postponed. Rather than delete it,
CloudNativePG, the Barman Cloud plugin and the cluster moved unchanged into
`core-talos/03-gitops/archive/`, which the root Application does not read.
Git recorded the move as renames, so nothing inside was rewritten, and
`archive/README.md` gives the two commands that bring it back.

The namespaces, twelve CRDs, both webhooks and the RBAC were then removed.
The last step deadlocked: the `barman-cloud` Service held the finalizer
`cnpg.io/cleanupPlugin` and the operator that clears it was already gone, so
the finalizer was removed by hand. The backups stay in R2 under
`cnpg/postgres-v2` with a completed base backup, and the archived Cluster
bootstraps from them, so bringing the setup back restores the data with it.

## Downloads and library, told apart

One directory, `hdd-a/media`, served as both: qBittorrent seeded exactly the
files Jellyfin played. Anything that organised a release would have broken
its torrent, and deleting a torrent would have deleted the film. The owner
also pointed out that the `Kids` directory mixed 13 films with 5 series,
which no *arr can model - age is metadata, not a folder.

`media` was renamed to `torrents` and an empty `media` created beside it. A
rename inside one XFS filesystem is instant, so 1.7 TB did not move, and a
bind mount follows the inode rather than the name, so nothing noticed until
the pods rolled onto the new name. qBittorrent keeps `/downloads` over the
renamed directory, because its 56 torrents carry that path in their resume
data, and gains `/data`, the whole disk, which is what Sonarr and Radarr also
mount: identical paths everywhere, so no download client path mapping.
Jellyfin keeps its migrated library through `/media`, now over `torrents`,
and gains `/library` for what the two managers build - so nothing stopped
playing. Samba gained a `torrents` share beside `media`.

Prowlarr, Sonarr and Radarr went into a namespace called `library`, the name
the owner chose over `arr`: torrent fetches, library organises, jellyfin
plays. They were written as three Deployments sharing one configuration
claim, which failed: the OpenEBS LVM driver refuses to mount a logical volume
into a second pod even on one node, so Prowlarr took it and the other two
never started. They now share one pod, as qBittorrent and Flood do.

The first claim also arrived broken, bound to a PV with no logical volume
behind it. The CSI log named the cause: csi-provisioner's leak protection
deleted the volume one second after creating it, because VolSync's populator
had removed the temporary `vs-prime-` claim it was provisioned for. It is a
race; deleting the claim and letting it be made again was enough. All three
traps are in `docs/traps.yaml`.

## Local names reach their certificate

The owner asked why the services had no certificates. They have one - TLS
ends at the Gateway, and the routes only claim a name - but the HTTP
listener carried no hostname, so it answered local names too and a name
typed without a scheme never reached HTTPS. A blanket redirect was not
available: cloudflared speaks plain HTTP to the same port, and redirecting
it would have looped every public name.

The listeners are now told apart by hostname. `*.serhii.link` on port 80 is
the tunnel's. `*.home` on port 80 admits routes from gateway-system alone
and holds one redirect to HTTPS - alone, because an exact hostname beats a
wildcard and any service route sharing that listener would take its own
name back. `ca.home` keeps a plain listener, since a device fetching the
root certificate does not trust it yet.

## Wiring the three together

The applications refuse to start unconfigured and ask the first visitor to
invent a password. They answer on local names only, so they were set to the
same posture as qBittorrent through `<APP>__AUTH__METHOD=External` in the
Deployment rather than through the dialog: a configuration restored from R2
would otherwise ask again. Those variables layer over `config.xml` at run
time and do not rewrite it, so the file still reads `None`.

The rest was done through each application's API, which is where that state
belongs - it lives in their SQLite databases and goes to R2 hourly:

- root folders `/data/media/movies` and `/data/media/tv`, made by an init
  container in the pod, because both applications reject a path that is not
  there and the library started empty;
- qBittorrent as the download client at
  `torrent.torrent.svc.cluster.local:8080`, which answers the pod network
  without a password; the connection test passes;
- its categories `radarr` and `sonarr` pointed at `/data/torrents/radarr`
  and `/data/torrents/sonarr`. The applications create the categories
  themselves but leave the path empty, which would drop everything in the
  root;
- Radarr and Sonarr registered in Prowlarr at full sync. All three share a
  pod, so they reach each other on localhost.

`copyUsingHardlinks` was already true in both, which is the setting that
matters most here.

## Choosing a language

The first series added came back as two Russian season packs from RuTracker.
Sonarr's profiles carry no language - it moved to custom formats in v4 - so
it compared only quality, and RuTracker's 1080p WEB-DL beat EZTV's 720p
WEBRip. Radarr had the opposite problem: its profile language was
`Original`, a hard filter that silently threw away every Ukrainian dub.

Both now work the same way. Language is a custom format, Radarr's profile
language is `Any`, and the six default profiles are gone: each application
keeps exactly two, `English` and `Ukrainian`. Each scores its own language
500 and the others 0, with a minimum score of 200, so the language is a
requirement rather than a preference - the profile takes nothing at all
rather than the wrong language, and waits for a translation to be posted.
The profile is chosen when a series or film is added, which is the whole
point: the owner's own watching is Ukrainian, their son's is not.

Both allow every quality from SDTV up to Bluray-1080p, since the best
allowed is what gets grabbed and nothing above 1080p is wanted on an N95.
Radarr's template had allowed everything, so a 60 GB BR-DISK outranked
1080p, and a film filmed in a cinema counted as a fallback; both ends are
switched off.

Toloka and Mazepa label their releases `Ukr/Eng` or `2xUkr/Eng`, and
Sonarr's parser reads both as Ukrainian and English, so the scores land
where they should. They are dual-audio, so "only Ukrainian" means "must
contain Ukrainian"; the track itself is chosen in Jellyfin.

Sonarr has no scheduled search for missing episodes, only an RSS sync every
15 minutes. A translation posted today is picked up within the quarter hour;
one posted before the series was added has fallen out of the feed and needs
the search pressed once by hand.

Renaming on import was off in both, which would have left release names in
the library and defeated half the reason for the stack. It is on.

## Where a file lives, and where to delete it

Two directories hold the same films. `/data/torrents` is qBittorrent's, and
`/data/media` is the library Sonarr and Radarr build out of hard links into
it. A hard link is a second name for one file, not a copy and not a
shortcut: neither name is the original, removing one leaves the other whole,
and the data goes only when the last name does. A seeding torrent therefore
cannot be broken by anything done in the library.

Nothing was retiring on its own: qBittorrent had no share limit, so torrents
seeded for ever, and neither manager was removing anything from the client.
The chain now closes by itself. A torrent that has given back twice what it
took, or seeded a fortnight, is stopped by qBittorrent - stopped, not
deleted, because that is what tells the managers seeding is done. They then
remove the torrent together with its file, but only for something they
managed to import, so a failed import never costs the download. The
library's link keeps the data, and Jellyfin notices nothing.

Deleting deliberately is one place: Sonarr or Radarr. Deleting in Jellyfin
is the worst of the options - it removes the library's link, frees nothing
because the torrent still holds the file, and leaves the episode looking
missing, so Sonarr downloads it again. Jellyfin is the reader here and is
better off without permission to delete at all.

## Importing what is already on the disk

The order matters, and it was learnt the wrong way round. A series added
with a search fires that search immediately, and since the library is empty
the search finds everything missing: MobLand was downloaded a second time
while its ten episodes, 35 GB, sat in `/data/torrents/Shows/MobLand`. The
order is to add without searching, import, and only then let it search - it
then looks for what is genuinely absent.

Two mechanisms carry similar names and only one is safe here. Library Import
declares a folder to *be* the library and adopts the files where they lie;
pointed at `/data/torrents` it would make the seeding directory the library,
and renaming would then rename files out from under 56 torrents. Manual
Import instead takes files from wherever they are and hard links them into
the root folder under proper names, which is what this migration needs.

Manual Import only fills series that already exist: a scan of the MobLand
folder returned all ten files as `Unknown Series` once the series had been
deleted. About 97 directories wait in `Shows`, `Movies` and `Kids`, so this
is a job for the API rather than an evening of clicking.

## Handoff

`prowlarr.home`, `sonarr.home` and `radarr.home` answer over HTTPS, are in
the certificate, and are wired to each other and to qBittorrent. Two things
are left, and both need a person.

Prowlarr has no indexers: which trackers, and any credentials they need, are
the owner's to choose. Everything else is already pointed at Prowlarr, so
adding one there puts it in both applications.

Then the import of about 97 directories, in the order above: add without
searching, Manual Import, then search. `Kids` needs no sorting, since each
item is identified on its own and lands in films or series. Releases named
in Ukrainian or Russian will need identifying by hand. Nothing stops
seeding, because the library is hard links.

All 56 torrents are complete and stopped, with no missing files - they were
already stopped before the rename. Jellyfin's `/media` mount and
qBittorrent's `/downloads` mount both exist only until the import is done.
