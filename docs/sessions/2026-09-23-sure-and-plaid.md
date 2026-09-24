---
date: 2026-09-23
title: Four institutions into Sure, and what it cost to get them
tags: [beelink, sure, plaid, snaptrade, simplefin, cloudflare, household]
hosts: [beelink]
---

# Four institutions into Sure, and what it cost to get them

Three banks and a Webull brokerage had to reach Sure. The providers were
evaluated in the wrong order, and the reasoning is in `decisions/0026`; what
follows is what it took.

SnapTrade went first because it is the only aggregator that reads Webull
directly, and the free Personal key does. Sure moved that integration to OAuth
in 0.7.3, a SnapTrade OAuth application belongs to a commercial workspace, and
the commercial track wants company details, a public website and a paid plan.
The wiring for it was added and reverted the same evening. SimpleFIN was the
other candidate and carries the three banks but not Webull, so it could never
have been the single provider.

Plaid covers all four and needs a redirect it can reach over public TLS, so
`sure.serhii.link` now exists behind Cloudflare Access, with no exemption for
Plaid's webhook: updates arrive by the worker polling. Sure builds the redirect
from the host the browser is on rather than from `APP_DOMAIN`, so `sure.home`
still serves everything except linking an account.

Linking Webull needed `we-promise/sure#3271`, which asks Plaid for the
liabilities product only when the account being linked is one; without it Plaid
hides investment-only institutions from its own search with no error. That
commit is not in 0.7.4 and no stable release carries it, so Sure runs
`0.7.5-alpha.10`. The prerelease was accepted while the database was 15 MB and
one day old, which is the cheapest that upgrade will ever be; five migrations
ran in about a second.

Market data came last. Yahoo Finance needs no key and refused a single ticker
on the first request - "rate limit exceeded" on one SPY lookup - so Twelve Data
was added beside it, on its free tier. Prices had also been skipped because the
security was marked `offline`: it was created during the Webull sync, before a
provider existed, and the flag stayed. Exchange rates remain empty and should:
every account is in USD.

Two things went wrong and are worth remembering. Registering the second
household member through the open onboarding created a **separate family**
rather than joining the existing one - the invitation flow at
`/invitations/new` is the path that joins, and `ONBOARDING_STATE: open` is what
offers the other one. The stranded user was moved by changing `family_id` and
its empty family deleted. And a newly published name looked broken for half an
hour on the LAN: `dnsmasq` on the router had cached the NXDOMAIN from before
the record existed, and macOS cached it again separately. See `traps.yaml`.

Money that is not the owner's was modelled rather than hidden. A 20,000 branch
deposit was split three ways - funds to pass on, reimbursement for purchases
made for relatives, and the owner's own share - with the first two excluded
along with the payments they match. What is left excluded nets to exactly the
1,000 still owed, which is an `OtherLiability` account of the same amount. The
account names gained their type at the same time: two accounts called
`Wells Fargo - Serhii` had already sent one query to the credit card instead of
the checking account.

The upstream defect found on the way is `we-promise/sure#3686`, with a fix in
`#3692`: Sure reads Plaid's `available_balance` only when `current_balance` is
nil, and Webull reports the positions' value there, or zero, keeping the cash
in `available_balance`. Two accounts, two people, 96,000 invisible between them.
