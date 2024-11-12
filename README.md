# factorio server infra (nixos on hetzner cloud + ofsm docker)

## Getting started
1. Install devenv
2. Create tfvars or set terraform cloud vars (see main.tf for vars)
3. Then
```
# enter dev shell
devenv shell

# create infra
terraform login # if needed
terraform init
terraform apply

# fetch configs from server
fs-nixos-update-configs

# provision config
fs-nixos-switch

# reboot server
fs-reboot
```
