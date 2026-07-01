{ pkgs, lib, mkSymlink, ... }:
let
  wallpaper = "~/.wallpaper";
  defaultWallpaper = "$HOME/.dotfiles/home/programs/hyprland/wallpapers/carina-nebula.png";
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

  xdg.configFile = {
    "hypr/animations.conf" = mkSymlink "config/animations.conf";
    "hypr/hypridle.conf" = mkSymlink "config/hypridle.conf";
    "hypr/hyprland.conf" = mkSymlink "config/hyprland.conf";
    "hypr/hyprlauncher.conf" = mkSymlink "config/hyprlauncher.conf";
    "hypr/hyprsunset.conf" = mkSymlink "config/hyprsunset.conf";
    "hypr/hyprtoolkit.conf" = mkSymlink "config/hyprtoolkit.conf";
    "hypr/input.conf" = mkSymlink "config/input.conf";
    "hypr/keybinds.conf" = mkSymlink "config/keybinds.conf";
    "hypr/monitors.conf" = mkSymlink "config/monitors.conf";
    "hypr/windows.conf" = mkSymlink "config/windows.conf";
    "hypr/local" = mkSymlink "config/local";

    "hypr/hyprpaper.conf".text = ''
      preload = ${wallpaper}
      wallpaper = ,${wallpaper}
    '';

    "hypr/hyprlock.conf".text = ''
      # BACKGROUND
      background {
          monitor =
          path = ${wallpaper}
          blur_passes = 3
          contrast = 0.8916
          brightness = 0.8172
          vibrancy = 0.1696
          vibrancy_darkness = 0.0
      }

      # GENERAL
      general {
          no_fade_in = false
          grace = 0
          disable_loading_bar = false
      }

      # TIME
      label {
          monitor =
          text = cmd[update:1000] echo "$(date +"%H:%M")"
          color = rgba(225, 225, 225, 0.75)
          font_size = 120
          font_family = SF Pro Display Bold
          position = 0, -140
          halign = center
          valign = top
      }

      # DAY-DATE-MONTH
      label {
          monitor =
          text = cmd[update:1000] echo "<span>$(LC_TIME=en_US.UTF-8 date '+%A, %d %B')</span>"
          color = rgba(225, 225, 225, 0.75)
          font_size = 30
          font_family = SF Pro Display Bold
          position = 0, 200
          halign = center
          valign = center
      }

      # USER
      label {
          monitor =
          text = Welcome back
          color = rgba(255, 255, 255, .65)
          font_size = 25
          font_family = SF Pro Display Bold
          position = 0, -70
          halign = center
          valign = center
      }

      # INPUT FIELD
      input-field {
          monitor =
          size = 290, 60
          outline_thickness = 2
          dots_size = 0.2 # Scale of input-field height, 0.2 - 0.8
          dots_spacing = 0.2 # Scale of dots' absolute size, 0.0 - 1.0
          dots_center = true
          outer_color = rgba(0, 0, 0, 0)
          inner_color = rgba(60, 56, 54, 0.35)
          font_color = rgb(200, 200, 200)
          fade_on_empty = false
          font_family = SF Pro Display Bold
          placeholder_text = <span foreground="##ffffff99">Password</span>
          hide_input = false
          position = 0, -140
          halign = center
          valign = center
      }
    '';
  };

  xdg.configFile."waypaper" = mkSymlink "waypaper";

  home.activation.wallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/.wallpaper" ]; then
      ln -sf "${defaultWallpaper}" "$HOME/.wallpaper"
    fi
  '';
}
