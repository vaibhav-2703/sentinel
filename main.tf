resource "digitalocean_kubernetes_cluster" "sentinel_cluster" {
  name    = "sentinel-cluster"
  region  = "blr1"  # Bangalore (Change to 'sgp1' if you picked Singapore)
  version = "1.32.1-do.0" # This picks the latest version automatically usually, or specify one

  node_pool {
    name       = "sentinel-pool"
    size       = "s-1vcpu-2gb" # The $12/mo node (covered by your credit)
    node_count = 1
  }
}