---
id: 0008
title: Nothing tells anyone when something breaks
status: open
date: 2026-09-06
tags: [monitoring, alerting, smart, backup, telegram, risk]
hosts: [core, proxmox]
---

Three things can fail quietly here, and all three currently do:

**A disk starts failing.** `smartd` polls both disks every 1800s and writes to
the journal. There is no `-m` recipient and OMV's SMTP settings hold the
placeholder `xxx`, so it tells nobody. The disks are unmirrored, which is what
makes this matter: `core.yaml` records `redundancy: none`.

**The backup stops running.** `restic-backup.timer` fires daily. A failure
leaves an entry in the journal that nobody reads. The failure mode that costs
the most is the silent one — a backup that has not run for two months looks
exactly like one that has.

**The machine does not come back.** No alert originating on `core` can report
this, by definition.

## The shape of the fix

Not "configure smartd". A channel is the small part; what feeds it is the
point. One script in the repository — `core/notify/notify.sh` — taking a line
of text and sending it, with two producers wired to it:

- `smartd`'s `-M exec`, for disk events
- `OnFailure=` on `restic-backup.service`, for backup failures

Keeping it in git is the reason to do it this way: a rebuild restores the
alerting along with everything else, instead of leaving it as a manual step
nobody remembers.

The third failure needs an off-box observer. A dead-man's switch —
healthchecks.io or equivalent, pinged by `backup.sh` on success — reports the
absence of a signal, which is the only way to catch a machine that never
started.

## Channel

Telegram, through a bot. It is gated by a token rather than by the obscurity of
a topic name, which rules out `ntfy.sh` in its accountless form: an unguessed
public topic is not privacy. SMTP through OMV would cover more of OMV's own
subsystems, but needs a mail account and delivers into an inbox that goes
unread for weeks; a push is harder to miss.

The token belongs in `/srv/ssd/docker/secrets/telegram/token`, alongside the
others, out of git.

## Status

Deferred by the owner on 2026-09-06 — the work is understood, the appetite is
elsewhere. Nothing blocks it but creating the bot.
