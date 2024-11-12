terraform {
  cloud {

    organization = "pavelpuchokcorp"

    workspaces {
      name = "live"
    }
  }

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
    hetznerdns = {
      source  = "timohirt/hetznerdns"
      version = "2.2.0"
    }
  }
}

variable "hcloud_token" {
  sensitive = true
}

variable "hdns_token" {
  sensitive = true
}

variable "ssh_pubkey_pluto" {
  sensitive = true
}

variable "domain_name" {
}

variable "subdomain_name" {
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "hetznerdns" {
  apitoken = var.hdns_token
}

resource "hcloud_ssh_key" "ssh_pluto" {
  name       = "Pluto's SSH Key"
  public_key = var.ssh_pubkey_pluto
}

resource "hcloud_server" "server" {
  name        = "server"
  image       = "debian-11"
  server_type = "cx22"
  location    = "fsn1" # https://docs.hetzner.com/cloud/general/locations/#what-locations-are-there

  ssh_keys  = [hcloud_ssh_key.ssh_pluto.id]
  user_data = "#cloud-config\nruncmd:\n- curl https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect | PROVIDER=hetznercloud NIX_CHANNEL=nixos-24.05 bash 2>&1 | tee /tmp/infect.log"
}

resource "hcloud_rdns" "server_domain" {
  server_id  = hcloud_server.server.id
  ip_address = hcloud_server.server.ipv4_address
  dns_ptr    = join(".", [var.subdomain_name, var.domain_name])
}

resource "hetznerdns_zone" "domain" {
  name = var.domain_name
  ttl  = 60
}

resource "hetznerdns_record" "factorio_domain" {
  zone_id = hetznerdns_zone.domain.id
  name    = var.subdomain_name
  value   = hcloud_server.server.ipv4_address
  type    = "A"
}

output "server_ip_addr" {
  value = hcloud_server.server.ipv4_address
}

output "server_domain" {
  value = hcloud_rdns.server_domain.dns_ptr
}
