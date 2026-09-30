# satellite

The cluster that watches core from outside and keeps copies of its backups:
Talos on the old OpenMediaVault box, to be `192.168.8.11`. Nothing may depend
on it - core runs the same without it. Why it exists and what it is for:
`../docs/decisions/0032-satellite-watches-core.md`.

- [`01-talos/`](01-talos/): Terraform-managed Talos configuration and the first install.
