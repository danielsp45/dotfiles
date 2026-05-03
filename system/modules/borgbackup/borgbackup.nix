{ ... }:
{
  services.borgmatic.enable = true;
  services.borgmatic.settings = {
    source_directories = [
      "/home/daniel"
      "/etc"
    ];
    exclude_patterns = [
      "/home/daniel/.cache"
      "/home/daniel/.local/share/Steam"
      "/home/daniel/Games"
    ];
    repositories = [
      { path = "/mnt/nas/.backups/trooper"; label = "nas"; }
    ];
    keep_daily = 7;
    keep_weekly = 4;
    keep_monthly = 6;
    checks = [ { name = "repository"; } ];
  };

  systemd.services.borgmatic = {
    requires = [ "mnt-nas.mount" ];
    after = [ "mnt-nas.mount" ];
    serviceConfig.Environment = [ "BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes" ];
  };

  systemd.timers.borgmatic = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 14:15:00";
      RandomizedDelaySec = "30m";
      Persistent = true;
    };
  };
}
