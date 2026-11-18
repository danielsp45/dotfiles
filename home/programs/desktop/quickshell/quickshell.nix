{ pkgs, mkSymlink, ... }:
{
  # libinput: its CLI feeds touchpad swipes to the overview (TouchpadGestures.qml).
  home.packages = [ pkgs.quickshell pkgs.libinput ];
  xdg.configFile."quickshell" = mkSymlink "config";
}
