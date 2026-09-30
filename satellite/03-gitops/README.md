# Flux-managed desired state

After `../02-platform/`, apply the root once, from the repository root:

```sh
kubectl --context satellite apply -f satellite/03-gitops/flux.yaml
```

It defines the `homelab` GitRepository and the root Kustomization, which
reconciles `apps/`. As on core, `apps/kustomization.yaml` names every
`ks.yaml` and nothing else, and each `ks.yaml` points at the `app/` beside it.

What runs here so far is the ground floor: the Infisical store External
Secrets reads from, the load balancer pool `.21-.29` with its L2
announcement, and OpenEBS LVM LocalPV with the `lvm` StorageClass on the
ORICO SSD. The thin-pool job never wipes a disk; `openebs` stays not Ready
until the ORICO is wiped by hand - see `../01-talos/README.md`, step 4. If the
job has used up its retries by then, delete it and Flux makes it again:

```sh
kubectl --context satellite -n openebs delete job ssd-thinpool
```
