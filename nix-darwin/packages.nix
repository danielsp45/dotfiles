{ pkgs, config, ... }:

{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
  [
    pkgs.vim
    pkgs.ansible
  ];

  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "uninstall";
      upgrade = true;
    };

    casks = [
      "google-chrome"
      "docker"
      "notion"
      "xquartz"
      "obsidian"
      "nikitabobko/tap/aerospace"
      "vmware-fusion"
      "telegram"
      "arc"
      "zed"
      "keybase"
      "spotify"
      "discord"
      "zotero"
      "alacritty"
      "font-iosevka-nerd-font"
      "1password"
      "1password-cli"
      "aldente"
      "raycast"
      "vagrant"
      "viscosity"
      "tailscale"
      "ghostty"
    ];

    brews = [
      "mas"
    ];

    masApps = {};

    onActivation = {
      autoUpdate = true;
      # WARN: only activate when full migration is complete
      # 'zap': uninstalls all formulae(and related files) not listed here.
      # cleanup = "zap";
    };
  };

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.package = pkgs.nixVersions.latest;
  nixpkgs.config.allowUnfree = true;
}
