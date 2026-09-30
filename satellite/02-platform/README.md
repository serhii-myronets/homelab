# Platform bootstrap

What has to run before Flux can: Cilium, External Secrets and the Flux
Operator, the same releases and versions as `../../core/02-platform/`. Applied
by hand with Helmfile, pinned to the kubeconfig context `satellite` - the
prepare hook's `kubectl` included, so a wrong current context fails rather
than lands on core.

1. Put an Infisical machine identity in `prepare-hook/initial-secret.yaml`,
   copied from the example with its client ID and secret base64-encoded; the
   file is ignored by Git. satellite uses core's identity, by the owner's
   choice on 2026-09-29: it reads all of `prod` in `homelab-ixx-o`, so a
   satellite broken into gives away every secret in the house, and revoking it
   stops both clusters. A separate identity, reading only `/satellite`, would
   close both - it was offered and set aside as not worth it yet.
2. Install the three releases. The hook applies the `external-secrets`
   namespace, the Gateway API CRDs and that credential first; the node turns
   Ready once Cilium runs:

   ```bash
   helmfile apply
   ```

3. Tell the operator which Flux controllers to run:

   ```bash
   kubectl --context satellite apply -f flux-instance.yaml
   ```

What differs from core: Cilium routes over `enp1s0` rather than a bridge, the
Flux web interface has no route until satellite has a Gateway and a name, and
the FluxInstance carries none of core's patches for fields Argo CD once owned.

Upgrades land here first: bump a version in this directory, apply, and move
core's only once satellite runs it.
