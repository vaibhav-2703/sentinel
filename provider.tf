terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# We will use an Environment Variable for the token so we don't hardcode secrets!
provider "digitalocean" {}