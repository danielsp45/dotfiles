{
  lib,
  hostname,
  ...
}:
let
  enableFor = hosts: lib.elem hostname hosts;
in
{
  # Core tools — all hosts
  dotfiles.programs.nvim.enable = true;
  dotfiles.programs.git.enable = true;
  dotfiles.programs.tmux.enable = true;
  dotfiles.programs.fastfetch.enable = true;
  dotfiles.programs.cli.enable = true;
  dotfiles.programs.direnv.enable = true;
  dotfiles.programs.starship.enable = true;
  dotfiles.programs.fonts.enable = true;

  # Dev tools — workstations and remote machines, not bare servers
  dotfiles.programs.dev.enable = enableFor [
    "trooper"
    "storm"
    "ubuntu-vagrant"
    "gsd-cluster"
  ];

  # Shell — all Linux hosts
  dotfiles.programs.zsh.enable = enableFor [
    "trooper"
    "storm"
    "pandora"
  ];

  # Terminals
  dotfiles.programs.alacritty.enable = enableFor [ "trooper" "storm" ];

  # btop config — all hosts (package provided by cli module)
  dotfiles.programs.btop.enable = true;

  # Desktop environment — graphical hosts only
  dotfiles.programs.ghostty.enable = enableFor [ "trooper" "storm" ];
  dotfiles.programs.hyprland.enable = enableFor [ "trooper" "storm" ];
  dotfiles.programs.waybar.enable = enableFor [ "trooper" "storm" ];
  dotfiles.programs.dunst.enable = enableFor [ "trooper" "storm" ];
  dotfiles.programs.swayosd.enable = enableFor [ "trooper" "storm" ];
  dotfiles.programs.walker.enable = enableFor [ "trooper" "storm" ];
  dotfiles.programs.quickshell.enable = enableFor [ "trooper" "storm" ];
  dotfiles.programs.rofi.enable = enableFor [ "trooper" "storm" ];
  dotfiles.programs.gtk.enable = enableFor [ "trooper" "storm" ];
  dotfiles.programs.scripts.enable = enableFor [ "trooper" "storm" ];

  # Desktop packages and apps
  dotfiles.programs.desktop.enable = enableFor [
    "trooper"
    "storm"
    "pandora"
  ];
  dotfiles.programs.apps.enable = enableFor [ "trooper" "storm" ];
  dotfiles.programs.feynman.enable = enableFor [ "trooper" "storm" ];
  dotfiles.programs.claude.enable = enableFor [ "trooper" "storm" "pandora" ];
  dotfiles.programs.zellij.enable = enableFor [ "trooper" "storm" "pandora" ];
  dotfiles.programs.espanso.enable = false;

  # Legacy X11 (inactive, configs preserved)
  dotfiles.programs.bspwm.enable = false;
  dotfiles.programs.polybar.enable = false;

  # macOS (darwin not yet migrated)
  dotfiles.programs.aerospace.enable = false;

  # Trooper-only
  dotfiles.programs.gaming.enable = enableFor [ "trooper" ];
  dotfiles.programs.amd.enable = enableFor [ "trooper" ];
  dotfiles.programs.workstation.enable = enableFor [ "trooper" ];

  # Storm-only
  dotfiles.programs.laptop.enable = enableFor [ "storm" ];
  dotfiles.programs.keychron.enable = enableFor [ "storm" ];

  # Server-only
  dotfiles.programs.server.enable = enableFor [ "pandora" ];
}
