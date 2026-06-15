{ pkgs, mkSymlink, hostname, ... }:
let
  workspacesConfig = {
    trooper = ''
      workspace = 1, monitor:DP-1, default:true
      workspace = 2, monitor:DP-1
      workspace = 3, monitor:DP-1
      workspace = 4, monitor:DP-1
      workspace = 5, monitor:DP-1
      workspace = 6, monitor:DP-1
      workspace = 7, monitor:DP-1
      workspace = 8, monitor:DP-1
      workspace = 9, monitor:DP-1
      workspace = 10, monitor:DP-2, persistent:true, default:true
    '';
    storm = ''
      workspace = 1, default:true
      workspace = 2
      workspace = 3
      workspace = 4
      workspace = 5
      workspace = 6
      workspace = 7
      workspace = 8
      workspace = 9
      workspace = 10
    '';
  };
in
{
  home.packages = with pkgs; [
    swaybg
    swaylock
    wayidle
    waypaper
    grim
    hyprshot
    satty
    slurp
    libnotify
    wf-recorder
    wl-screenrec
    ffmpeg
    hyprpicker
    hypridle
    hyprsunset
    hyprlock
    hyprtoolkit
    rose-pine-hyprcursor
    wtype
  ];
  xdg.configFile."hypr" = mkSymlink "config";
  xdg.configFile."waypaper" = mkSymlink "waypaper";
  xdg.configFile."hypr-local/workspaces.conf".text =
    workspacesConfig.${hostname} or "";
}
