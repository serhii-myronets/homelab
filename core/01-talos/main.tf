terraform {
  required_version = ">= 1.5.0"

  # State in R2, beside the backups, so the cluster can be rebuilt without
  # this Mac. Credentials come from the r2 profile in ~/.aws/credentials - the
  # backup key pair in Infisical /system/backups. The state holds the cluster's
  # keys in the clear (the secrets read from Infisical sit in it), and the cluster's own
  # R2 key can read this bucket: accepted, see docs/decisions/0037. No lock
  # table - one administrator.
  backend "s3" {
    bucket                      = "homelab-backups"
    key                         = "terraform/core-01-talos.tfstate"
    region                      = "auto"
    endpoints                   = { s3 = "https://32bd020558a0bb7293a40decd3f7b161.r2.cloudflarestorage.com" }
    profile                     = "r2"
    use_path_style              = true
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true # R2 does not take the AWS SDK's default checksums
  }
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "0.11.0"
    }
    infisical = {
      source  = "infisical/infisical"
      version = "0.19.38"
    }
  }
}

# Infisical as the owner, with the CLI session's token that a terraform
# function in ~/.zshrc hands to each run (README.md, "Infisical").
provider "infisical" {}

# worker-1's address in maintenance mode, before its first configuration
# gives it worker_1_ip. Pass it once, for the first apply:
#   terraform apply -var worker_1_bootstrap_endpoint=<address>
variable "worker_1_bootstrap_endpoint" {
  type    = string
  default = null
}

locals {
  cluster_name       = "core"
  node_ip            = "192.168.8.10"
  worker_1_ip        = "192.168.8.11"
  talos_version      = "v1.14.1"
  kubernetes_version = "1.37.0"
  schematic          = "4b3cd373a192c8469e859b7a0cfbed3ecc3577c4a2d346a37b0aeff9cd17cdb0"

  # This project, homelab: SECRETS_YAML under talos_path is what the cluster
  # is made from; TALOSCONFIG and KUBECONFIG beside it, Terraform writes.
  infisical = {
    project_id = "0f683ac6-7321-435c-935e-3e68f72f2d60"
    talos_path = "/system/talos"
  }
}

# The cluster's Talos secrets, read from Infisical on every run - the copy
# of secrets.yaml kept there since docs/decisions/0037. Until 2026-10-04 they
# were imported into the state as talos_machine_secrets.cluster.
data "infisical_secrets" "talos" {
  workspace_id = local.infisical.project_id
  env_slug     = "prod"
  folder_path  = local.infisical.talos_path
}

locals {
  talos_secrets = yamldecode(data.infisical_secrets.talos.secrets["SECRETS_YAML"].value)

  # secrets.yaml's names, as the Talos provider spells them.
  machine_secrets = {
    cluster = {
      id     = local.talos_secrets.cluster.id
      secret = local.talos_secrets.cluster.secret
    }
    secrets = {
      bootstrap_token             = local.talos_secrets.secrets.bootstraptoken
      secretbox_encryption_secret = local.talos_secrets.secrets.secretboxencryptionsecret
      aescbc_encryption_secret    = try(local.talos_secrets.secrets.aescbcencryptionsecret, null)
    }
    trustdinfo = {
      token = local.talos_secrets.trustdinfo.token
    }
    certs = {
      etcd               = { cert = local.talos_secrets.certs.etcd.crt, key = local.talos_secrets.certs.etcd.key }
      k8s                = { cert = local.talos_secrets.certs.k8s.crt, key = local.talos_secrets.certs.k8s.key }
      k8s_aggregator     = { cert = local.talos_secrets.certs.k8saggregator.crt, key = local.talos_secrets.certs.k8saggregator.key }
      k8s_serviceaccount = { key = local.talos_secrets.certs.k8sserviceaccount.key }
      os                 = { cert = local.talos_secrets.certs.os.crt, key = local.talos_secrets.certs.os.key }
    }
  }
}

# Forgotten, not destroyed: the secrets are read from Infisical instead.
removed {
  from = talos_machine_secrets.cluster
  lifecycle {
    destroy = false
  }
}

# The admin's Talos client configuration, made from the secrets on each run
# and never stored: valid as long as the OS CA, and the same every time.
ephemeral "talos_client_configuration" "cluster" {
  cluster_name    = local.cluster_name
  machine_secrets = local.machine_secrets
  endpoints       = [local.node_ip]
  nodes           = [local.node_ip]
}

data "talos_machine_configuration" "controlplane" {
  cluster_name       = local.cluster_name
  cluster_endpoint   = "https://${local.node_ip}:6443"
  machine_type       = "controlplane"
  machine_secrets    = local.machine_secrets
  talos_version      = "v1.13"
  kubernetes_version = local.kubernetes_version
  config_patches = [
    file("${path.module}/patches/controlplane/controlplane.yaml"),
    file("${path.module}/patches/controlplane/hostname.yaml"),
    file("${path.module}/patches/controlplane/network.yaml"),
    file("${path.module}/patches/common/cilium.yaml"),
    file("${path.module}/patches/controlplane/storage.yaml"),
    file("${path.module}/patches/controlplane/swap.yaml"),
    yamlencode({ machine = { install = {
      image = "factory.talos.dev/metal-installer/${local.schematic}:${local.talos_version}"
    } } })
  ]
}

# worker-1, on the machine called satellite, a worker since 2026-09-30: the
# cluster-wide settings every node shares, then its own disk, bridge, name and
# swap. See docs/decisions/0034.
data "talos_machine_configuration" "worker_1" {
  cluster_name       = local.cluster_name
  cluster_endpoint   = "https://${local.node_ip}:6443"
  machine_type       = "worker"
  machine_secrets    = local.machine_secrets
  talos_version      = "v1.13"
  kubernetes_version = local.kubernetes_version
  config_patches = [
    file("${path.module}/patches/common/cilium.yaml"),
    file("${path.module}/patches/worker/node.yaml"),
    file("${path.module}/patches/worker/hostname.yaml"),
    file("${path.module}/patches/worker/network.yaml"),
    file("${path.module}/patches/worker/swap.yaml"),
    yamlencode({ machine = { install = {
      image = "factory.talos.dev/metal-installer/${local.schematic}:${local.talos_version}"
    } } })
  ]
}

resource "talos_machine_configuration_apply" "controlplane" {
  node                        = local.node_ip
  endpoint                    = local.node_ip
  client_configuration_wo     = ephemeral.talos_client_configuration.cluster.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  on_destroy                  = { reset = false, graceful = true, reboot = false }
  lifecycle {
    prevent_destroy = true
  }
}

resource "talos_machine_configuration_apply" "worker_1" {
  node                        = coalesce(var.worker_1_bootstrap_endpoint, local.worker_1_ip)
  endpoint                    = coalesce(var.worker_1_bootstrap_endpoint, local.worker_1_ip)
  client_configuration_wo     = ephemeral.talos_client_configuration.cluster.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker_1.machine_configuration
  on_destroy                  = { reset = false, graceful = true, reboot = false }
  # Not ignore_changes on node and endpoint: that kept the maintenance address
  # in state for good, and every later apply went to it and hung. See traps.
  lifecycle {
    prevent_destroy = true
  }
}

moved {
  from = talos_machine_configuration_apply.satellite
  to   = talos_machine_configuration_apply.worker_1
}

resource "talos_machine_bootstrap" "cluster" {
  depends_on              = [talos_machine_configuration_apply.controlplane]
  node                    = local.node_ip
  endpoint                = local.node_ip
  client_configuration_wo = ephemeral.talos_client_configuration.cluster.client_configuration
  lifecycle {
    prevent_destroy = true
  }
}

# The kubeconfig came from the running cluster until 2026-10-04; it is made
# from the secrets now (clients.tf).
removed {
  from = talos_cluster_kubeconfig.cluster
  lifecycle {
    destroy = false
  }
}
