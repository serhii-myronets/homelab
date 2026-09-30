---
id: "0033"
title: satellite signs .home with an intermediate of home-ca
date: 2026-09-30
status: accepted
tags: [satellite, tls, cert-manager, home-ca, infisical, pki]
hosts: [satellite, core]
---

# satellite signs .home with an intermediate of home-ca

satellite serves its own `.home` names over HTTPS, so that they open without a
warning on every device that already trusts home-ca, and without core.

It signs with an intermediate CA, `Homelab satellite Intermediate`, that
home-ca signed once on 2026-09-30: EC P-256, `pathlen:0`, a critical name
constraint permitting only `home`, valid until 2031-09-29. Its key and its
chain (intermediate, then root) live in Infisical, prod `/satellite`, and an
ExternalSecret hands them to satellite's cert-manager as the `home-ca`
ClusterIssuer - named as core's, so a Certificate reads the same on both.
home-ca's own key never left core except for the signing, in a scratch
directory deleted straight after.

The constraint is what makes a copy of this key tolerable: anyone holding it
can sign for `.home` and nothing else, so a device that trusts home-ca cannot
be handed a forged certificate for any real site through it.

## Rejected

- Infisical PKI, which was the first choice: an intermediate CA held and
  operated by Infisical, signed by home-ca, with the infisical-pki-issuer
  addon for cert-manager on each cluster. Infisical's free plan refuses to
  import an externally signed certificate for an intermediate - see
  traps.yaml - and the alternative, an Infisical root, would mean trusting a
  new root on every device.
- Copying home-ca itself into Infisical: simplest, but its key could then sign
  for any name, and would sit in Infisical and both clusters.
- A separate root for satellite: another certificate to install everywhere.
- Serving satellite's names through core's Gateway: nothing to sign at all,
  but satellite's consoles would go dark exactly when core does.

## Consequences

The intermediate must be signed again before 2031-09-29, by hand, the same
way. home-ca itself renews in 2035 (ten years, renewed one before), and
cert-manager rotates the key when it does; every device would then need the
new root, and this intermediate would stop chaining - by then it has lapsed
anyway, but core's own certificates would face the same.

Every satellite name under `.home` needs its own rewrite on the router,
since `*.home` points at core; an exact rewrite outranks the wildcard in
AdGuard Home, to be tested on this router.
