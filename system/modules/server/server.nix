{ config, pkgs, lib, ... }:
{
  environment.etc."glance".source = ../../../home/programs/glance;
  environment.etc."adguard/conf".source = ../../../home/programs/adguard/conf;

  services.resolved.enable = lib.mkForce false;

  services.adguardhome = {
    enable = true;
    openFirewall = true;
    settings.host = "100.81.92.40";
  };

  virtualisation.oci-containers = {
    backend = "docker";
    containers.nginx-proxy-manager = {
      image = "docker.io/jc21/nginx-proxy-manager:latest";
      autoStart = true;
      ports = [ "80:80" "81:81" "443:443" ];
      volumes = [
        "/var/lib/npm/data:/data"
        "/var/lib/npm/letsencrypt:/etc/letsencrypt"
      ];
      environment.TZ = "Europe/Lisbon";
    };
    containers.couchdb = {
      image = "couchdb";
      ports = [ "5984:5984" ];
      environment = {
        COUCHDB_USER = "admin";
        COUCHDB_PASSWORD = "admin";
      };
      volumes = [
        "/mnt/truenas/couchdb/data:/opt/couchdb/data"
        "/mnt/truenas/couchdb/etc:/opt/couchdb/etc/local.d"
        "/mnt/truenas/couchdb/logs:/opt/couchdb/var/log"
      ];
      extraOptions = [ "--restart=unless-stopped" ];
    };
  };

  systemd.tmpfiles.rules = [ "d /var/lib/glance 0755 root root -" ];

  systemd.services.glance-compose = {
    description = "Glance via docker compose";
    after = [ "docker.service" "network-online.target" ];
    wants = [ "docker.service" "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      WorkingDirectory = "/etc/glance";
      ExecStartPre = [
        ''${pkgs.docker}/bin/docker compose -p glance down --remove-orphans || true''
        ''${pkgs.docker}/bin/docker rm -f glance || true''
      ];
      ExecStart = ''${pkgs.docker}/bin/docker compose -p glance up -d --remove-orphans'';
      ExecStop = ''${pkgs.docker}/bin/docker compose -p glance down'';
      RemainAfterExit = true;
    };
    restartTriggers = [ config.environment.etc."glance".source ];
  };

  networking.firewall.allowedTCPPorts = [ 80 81 443 8080 8384 5984 ];
}
