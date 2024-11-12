{ pkgs, lib, config, inputs, ... }:
{
  #env.NIXOS_CONFIG = "$(pwd)/nixos/configuration.nix";

  cachix.enable = false;

  packages = with pkgs; [ git openssh nixos-rebuild ];

  languages.terraform.enable = true;
  languages.terraform.version = "1.9";

  # https://devenv.sh/processes/
  # processes.cargo-watch.exec = "cargo-watch";

  # https://devenv.sh/services/
  # services.postgres.enable = true;
  scripts = {
    "fs-nixos-update-configs".exec = ''
            IP="$(terraform output -raw server_ip_addr)"
            HOST="root@$IP"
            echo "Copying host's specific configuration file. Source Host: $HOST"
            scp "$HOST":/etc/nixos/networking.nix ./nixos/
            scp "$HOST":/etc/nixos/hardware-configuration.nix ./nixos/

            DOMAIN="$(terraform output -raw server_domain)"
            echo "Generating variables.nix"
            cat > ./nixos/variables.nix << EOL
{
    fs_domain_name = "$DOMAIN";
    fs_cert_email = "admin@$DOMAIN";
}
EOL'';
    "fs-nixos-switch".exec = ''
      NIXOS_CONFIG="$(pwd)/nixos/configuration.nix"
      HOST="root@$(terraform output -raw server_ip_addr)"
      echo "Rebuild configuration. Host: $HOST, Configuration File: $NIXOS_CONFIG"
      NIXOS_CONFIG="$NIXOS_CONFIG" nixos-rebuild switch --target-host $HOST
    '';
    "fs-reboot".exec = ''
      HOST="root@$(terraform output -raw server_ip_addr)"
      echo "Reboot host: $HOST"
      ssh $HOST reboot
    '';
  };

  enterShell = ''
    echo "Hello into a factorio server dev shell."
    git --version
  '';

  # https://devenv.sh/tasks/
  # tasks = {
  # "myproj:setup".exec = "mytool build";
  # "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
  '';

  # https://devenv.sh/pre-commit-hooks/
  # pre-commit.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
