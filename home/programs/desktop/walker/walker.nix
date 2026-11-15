{ config, pkgs, mkSymlink, ... }:
{
  home.packages = [ pkgs.walker pkgs.elephant ];
  xdg.configFile."walker" = mkSymlink "config";

  # Elephant is walker's backend; it indexes .desktop files once and then
  # watches the app directories. Those directories are symlinks into the Nix
  # store that a rebuild swaps out, so newly installed apps never showed up
  # until a reboot. Run it as a user service and restart it whenever the
  # package set changes (home-manager restarts units whose file changed).
  systemd.user.services.elephant = {
    Unit = {
      Description = "Elephant, data provider for the walker launcher";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      X-Restart-Triggers = [ "${config.home.path}" ];
    };
    Service = {
      ExecStart = "${pkgs.elephant}/bin/elephant";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Walker keeps a connection to elephant, so restart it along with elephant.
  systemd.user.services.walker = {
    Unit = {
      Description = "Walker launcher";
      PartOf = [ "graphical-session.target" "elephant.service" ];
      Requires = [ "elephant.service" ];
      After = [ "graphical-session.target" "elephant.service" ];
    };
    Service = {
      ExecStart = "${pkgs.walker}/bin/walker --gapplication-service";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
