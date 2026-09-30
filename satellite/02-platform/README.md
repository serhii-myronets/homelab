# Platform bootstrap

What has to run before Flux can: Cilium, External Secrets and the Flux
Operator, the same releases and versions as `../../core/02-platform/`. Applied
by hand with Helmfile, pinned to the kubeconfig context `satellite` - the
prepare hook's `kubectl` included, so a wrong current context fails rather
than lands on core.

1. Give satellite its own Infisical machine identity, never core's: Universal
   Auth, in project `homelab-ixx-o`, with a role that reads `prod` under
   `/satellite` and nothing else. Copy `prepare-hook/initial-secret.yaml.example`
   to `prepare-hook/initial-secret.yaml` and fill in its client ID and secret,
   base64-encoded. The file is ignored by Git.
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
