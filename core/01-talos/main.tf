terraform {
  required_version = ">= 1.5.0"
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "0.11.0"
    }
  }
}

# satellite's address in maintenance mode, before its first configuration
# gives it satellite_ip. Pass it once, for the first apply:
#   terraform apply -var satellite_bootstrap_endpoint=<address>
variable "satellite_bootstrap_endpoint" {
  type    = string
  default = null
}

locals {
  cluster_name       = "core"
  node_ip            = "192.168.8.10"
  satellite_ip       = "192.168.8.11"
  talos_version      = "v1.14.1"
  kubernetes_version = "1.37.0"
  schematic          = "4b3cd373a192c8469e859b7a0cfbed3ecc3577c4a2d346a37b0aeff9cd17cdb0"
}

resource "talos_machine_secrets" "cluster" {
  # Imported from secrets.yaml; retain its original version contract.
  lifecycle {
    prevent_destroy = true
  }
}

data "talos_machine_configuration" "controlplane" {
  cluster_name       = local.cluster_name
  cluster_endpoint   = "https://${local.node_ip}:6443"
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.cluster.machine_secrets
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

# satellite, a worker since 2026-09-30: the cluster-wide settings every node
# shares, then its own disk, bridge, name and swap. See docs/decisions/0034.
data "talos_machine_configuration" "satellite" {
  cluster_name       = local.cluster_name
  cluster_endpoint   = "https://${local.node_ip}:6443"
  machine_type       = "worker"
  machine_secrets    = talos_machine_secrets.cluster.machine_secrets
  talos_version      = "v1.13"
  kubernetes_version = local.kubernetes_version
  config_patches = [
    file("${path.module}/patches/common/cilium.yaml"),
    file("${path.module}/patches/worker/node.yaml"),
    file("${path.module}/patches/worker/network.yaml"),
    file("${path.module}/patches/worker/swap.yaml"),
    yamlencode({ machine = { install = {
      image = "factory.talos.dev/metal-installer/${local.schematic}:${local.talos_version}"
    } } })
  ]
}

data "talos_client_configuration" "cluster" {
  cluster_name         = local.cluster_name
  client_configuration = talos_machine_secrets.cluster.client_configuration
  endpoints            = [local.node_ip]
  nodes                = [local.node_ip]
}

resource "talos_machine_configuration_apply" "controlplane" {
  node                        = local.node_ip
  endpoint                    = local.node_ip
  client_configuration        = talos_machine_secrets.cluster.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  on_destroy                  = { reset = false, graceful = true, reboot = false }
  lifecycle {
    prevent_destroy = true
  }
}

resource "talos_machine_configuration_apply" "satellite" {
  node                        = coalesce(var.satellite_bootstrap_endpoint, local.satellite_ip)
  endpoint                    = coalesce(var.satellite_bootstrap_endpoint, local.satellite_ip)
  client_configuration        = talos_machine_secrets.cluster.client_configuration
  machine_configuration_input = data.talos_machine_configuration.satellite.machine_configuration
  on_destroy                  = { reset = false, graceful = true, reboot = false }
  # Not ignore_changes on node and endpoint: that kept the maintenance address
  # in state for good, and every later apply went to it and hung. See traps.
  lifecycle {
    prevent_destroy = true
  }
}

resource "talos_machine_bootstrap" "cluster" {
  depends_on           = [talos_machine_configuration_apply.controlplane]
  node                 = local.node_ip
  endpoint             = local.node_ip
  client_configuration = talos_machine_secrets.cluster.client_configuration
  lifecycle {
    prevent_destroy = true
  }
}

resource "talos_cluster_kubeconfig" "cluster" {
  depends_on           = [talos_machine_bootstrap.cluster]
  node                 = local.node_ip
  client_configuration = talos_machine_secrets.cluster.client_configuration
}

output "talosconfig" {
  value     = data.talos_client_configuration.cluster.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.cluster.kubeconfig_raw
  sensitive = true
}
