terraform {
  required_version = ">= 1.5.0"
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "0.11.0"
    }
  }
}

# The address the node answers on in maintenance mode, before the first
# configuration gives it node_ip. Pass it once, for the first apply:
#   terraform apply -var bootstrap_endpoint=192.168.8.100
variable "bootstrap_endpoint" {
  type    = string
  default = null
}

locals {
  cluster_name       = "satellite"
  node_ip            = "192.168.8.20"
  talos_version      = "v1.14.1"
  kubernetes_version = "1.37.0"
  # The same image as core's: i915 and intel-ucode, both generic Intel.
  schematic = "4b3cd373a192c8469e859b7a0cfbed3ecc3577c4a2d346a37b0aeff9cd17cdb0"
}

# Its own secrets, never core's: shared ones would let either cluster's
# credentials into the other, and satellite exists to be out of core's reach.
resource "talos_machine_secrets" "cluster" {
  talos_version = "v1.13"
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
    file("${path.module}/patches/controlplane.yaml"),
    file("${path.module}/patches/network.yaml"),
    file("${path.module}/patches/cilium.yaml"),
    file("${path.module}/patches/storage.yaml"),
    file("${path.module}/patches/swap.yaml"),
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
  node                        = coalesce(var.bootstrap_endpoint, local.node_ip)
  endpoint                    = coalesce(var.bootstrap_endpoint, local.node_ip)
  client_configuration        = talos_machine_secrets.cluster.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  on_destroy                  = { reset = false, graceful = true, reboot = false }
  lifecycle {
    prevent_destroy = true
    # The endpoint changes once, from the maintenance address to node_ip.
    ignore_changes = [node, endpoint]
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
