---
id: "0027"
title: Archive Actual Budget; Sure keeps the budgets
date: 2026-09-26
status: accepted
tags: [beelink, actual, sure, finance, archive]
---

# Archive Actual Budget; Sure keeps the budgets

Actual and Sure were both running for the household's money, built on
consecutive days. Sure is the one connected to the four institutions through
Plaid ([0026](0026-sure-goes-public-for-plaid.md)); Actual has no Plaid
integration of its own, only community tools that sync transactions and
nothing on the brokerage side. Two budgets for one household is one too many.

Actual goes to `archive/actual/` whole, and Flux deletes its claim. Its one
budget is kept in R2 by the last VolSync run, and the same manifests restore
it from there, so archiving costs no data.

Keeping Actual and dropping Sure was the alternative, and the lighter one by
far: 62 MiB against about a gigabyte. It was rejected because it cannot reach
Webull or hold the investment side at all, and replacing Sure's Plaid
connections would spend Plaid Trial slots that do not come back.
