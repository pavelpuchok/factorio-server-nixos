{ config, lib, ... }:

let inherit (import ./variables.nix) fs_domain_name fs_cert_email;
in

{
  # configuration from https://github.com/OpenFactorioServerManager/factorio-server-manager/blob/develop/docker/docker-compose.yaml


  config.system.activationScripts.makeOFSMDir = lib.stringAfter [ "var" ] ''
    mkdir -p /var/lib/ofsm/fsm-data
    mkdir -p /var/lib/ofsm/factorio-data/saves/
    mkdir -p /var/lib/ofsm/factorio-data/mods/
    mkdir -p /var/lib/ofsm/factorio-data/config/
    mkdir -p /var/lib/ofsm/factorio-data/mod_packs/
  '';

  config.system.activationScripts.makeTraefikDir = lib.stringAfter [ "var" ] ''
    mkdir -p /var/lib/traefik/traefik-data
  '';


  config.virtualisation.oci-containers.containers = {
    ofsm = {
      autoStart = true;

      image = "ofsm/ofsm:latest";
      environment = {
        RCON_PASS = "";
        DOMAIN_NAME = "${fs_domain_name}";
        EMAIL_ADDRESS = "${fs_cert_email}";
        #FACTORIO_VERSION = "2.0.15";
      };

      labels = {
        "traefik.enable" = "true";

        "traefik.http.routers.fsm.entrypoints" = "websecure";
        "traefik.http.routers.fsm.rule" = "Host(`${fs_domain_name}`)";
        "traefik.http.routers.fsm.tls" = "true";
        "traefik.http.routers.fsm.tls.certResolver" = "default";
        "traefik.http.routers.fsm.service" = "fsm";
        #"traefik.http.routers.fsm.middlewares"="fsm-auth";
        "traefik.http.services.fsm.loadbalancer.server.port" = "80";

        "traefik.udp.routers.fsm.entrypoints" = "factorio";
        "traefik.udp.routers.fsm.service" = "fsm";
        "traefik.udp.services.fsm.loadbalancer.server.port" = "34197";
      };

      volumes = [
        "/var/lib/ofsm/fsm-data:/opt/fsm-data"
        "/var/lib/ofsm/factorio-data/saves:/opt/factorio/saves"
        "/var/lib/ofsm/factorio-data/mods:/opt/factorio/mods"
        "/var/lib/ofsm/factorio-data/config:/opt/factorio/config"
        "/var/lib/ofsm/factorio-data/mod_packs:/opt/fsm/mod_packs"
      ];
    };

    traefik = {
      autoStart = true;

      image = "traefik:v2.2";
      labels = {
        "traefik.enable" = "true";
      };

      cmd = [
        "--entrypoints.web.address=:80"
        "--entrypoints.websecure.address=:443"
        "--entrypoints.factorio.address=:34197/udp"

        "--entrypoints.web.http.redirections.entryPoint.to=websecure"
        "--entrypoints.web.http.redirections.entryPoint.scheme=https"

        "--providers.docker"
        "--providers.docker.exposedByDefault=false"

        "--certificatesresolvers.default.acme.email=${fs_cert_email}"
        "--certificatesresolvers.default.acme.storage=/etc/traefik/acme.json"
        "--certificatesresolvers.default.acme.tlschallenge=true"
      ];

      ports = [
        "80:80"
        "443:443"
        "34197:34197/udp"
      ];

      volumes = [
        "/run/user/0/podman/podman.sock:/var/run/docker.sock:z"
        "/var/lib/traefik/traefik-data:/etc/traefik"
      ];
    };
  };


}
