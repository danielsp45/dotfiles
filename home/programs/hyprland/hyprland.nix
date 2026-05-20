{ pkgs, mkSymlink, ... }:
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
    hyprlauncher
    hyprtoolkit
    rose-pine-hyprcursor
    wtype
  ];
  xdg.configFile."hypr" = mkSymlink "config";
  xdg.configFile."waypaper" = mkSymlink "waypaper";
}
