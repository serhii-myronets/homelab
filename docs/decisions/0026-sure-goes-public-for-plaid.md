---
id: "0026"
title: Publish Sure so Plaid can reach it, and drop the other two providers
date: 2026-09-23
status: accepted
tags: [beelink, sure, plaid, snaptrade, simplefin, cloudflare, privacy, finance]
---

# Publish Sure so Plaid can reach it, and drop the other two providers

Four accounts had to reach Sure: Chase, Bank of America, Wells Fargo and a
Webull brokerage. Plaid covers all four. Its free Trial plan, which replaced
Limited Production for teams created after 2026-04-15, gives real production
data for ten Items and names those three banks as available OAuth
institutions; Webull connects through Plaid as `Webull Financial` and shares
read-only account data, which Webull's own help documents.

Plaid will not accept a redirect URI it cannot reach over public TLS, so
`sure.home` cannot serve it - the name resolves only on the LAN and its
certificate comes from the home authority. `sure.serhii.link` therefore exists,
through the Beelink tunnel and behind Cloudflare Access like the other eight
published names. Sure builds the redirect from the host the browser is on, not
from `APP_DOMAIN`, so accounts are linked from the public name and used from
either. Access covers the whole domain with no exemption for Plaid's webhook:
provider updates arrive by the worker polling instead of being pushed, and the
gate stays whole. Investments refresh about once a trading day either way.

This is a deliberate reversal. Until today Sure was local-only "while Plaid
callback requirements are evaluated", and the evaluation concluded that the
requirement is real and worth meeting: publishing buys all four institutions
from one provider, not the fifteen dollars a year that the alternative saves.

SnapTrade was tried first and abandoned. It is the only aggregator that reads
Webull directly, and the free Personal API key does so - but Sure moved its
SnapTrade integration to OAuth in 0.7.3, and a SnapTrade OAuth application
belongs to a commercial workspace, behind company details, policies, a public
application website and a paid plan. The Personal key Sure cannot accept and
the commercial application is not worth registering a company for. The wiring
added for it was reverted the same day.

SimpleFIN was the other candidate and stays unused. It needs no public name at
all, which was its whole appeal, and its catalogue carries the three banks -
but not Webull, so it could never have been the single provider. Paying it
fifteen dollars a year to cover three of four, while Webull went in by hand,
lost to one provider covering everything.

Linking an investment-only brokerage needs `we-promise/sure#3271`, which asks
Plaid for the liabilities product only when the account being linked is one.
Without it Plaid hides such institutions from its own search with no error.
That commit is not in 0.7.4 and no stable release carries it, so Sure runs the
0.7.5-alpha.10 prerelease - accepted while its database was 15 MB and one day
old, which is the cheapest this upgrade will ever be.
