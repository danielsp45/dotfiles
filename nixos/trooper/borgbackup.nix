{ config, pkgs, lib, ... }:

{
  services.borgmatic.enable = true;

  # One named borgmatic config called "trooper"
  services.borgmatic.settings = {
    location = {
      source_directories = [
        "/home/daniel"
        "/etc"
      ];
      # optional exclusions
      exclude_patterns = [
        "/home/daniel/.cache"
        "/home/daniel/.local/share/Steam"
        "/home/daniel/Games"
      ];
    };

    storage = {
      repositories = [
        { path = "/mnt/nas/.backups/trooper"; label = "nas"; }
      ];
    };

    retention = {
      keep_daily = 7;
      keep_weekly = 4;
      keep_monthly = 6;
    };

    consistency = {
      checks = [ "repository" ];
    };
  };

  # Make borgmatic pull in /mnt/nas when it runs (and order after it).
  systemd.services.borgmatic = {
    requires = [ "mnt-nas.mount" ];
    after = [ "mnt-nas.mount" ];
    serviceConfig = {
      Environment = [
        "BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes"
      ];
    };
  };

  systemd.timers.borgmatic = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      # OnCalendar = "daily";
      OnCalendar = "*-*-* 14:15:00";
      RandomizedDelaySec = "30m";
      Persistent = true;
    };
  };
}
