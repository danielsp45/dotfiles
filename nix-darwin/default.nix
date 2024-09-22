{ pkgs, config, ... }:

{
    users.users.danielsp_45 = {
        name = "danielsp_45";
        home = "/Users/danielsp_45";
    };

    # List packages installed in system profile. To search by name, run:
    # $ nix-env -qaP | grep wget
    environment.systemPackages =
    [ 
        pkgs.vim
    ];

    # Auto upgrade nix package and the daemon service.
    services.nix-daemon.enable = true;
    nix.package = pkgs.nixVersions.latest;

    # Necessary for using flakes on this system.
    nix.settings.experimental-features = "nix-command flakes";

    # Create /etc/zshrc that loads the nix-darwin environment.
    programs.zsh.enable = true;  # default shell on catalina
    # programs.fish.enable = true;

    # Set Git commit hash for darwin-version.
    # system.configurationRevision = self.rev or self.dirtyRev or null;

    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    system.stateVersion = 4;

    # The platform the configuration will be used on.
    nixpkgs.hostPlatform = "aarch64-darwin";

    system.defaults = {
        dock.autohide = true;
        dock.orientation = "bottom";
    };

    homebrew = {
        enable = true;

        casks = [
          "google-chrome"
          "karabiner-elements"
          "aerospace"
          "docker"
          "notion"
          "xquartz"
          "obsidian"
        ];

        brews = [
        ];
    };

    security.pam.enableSudoTouchIdAuth = true;
}
