{ pkgs, config, ... }:

{
    users.users.daniel = {
        name = "daniel";
        home = "/Users/daniel";
    };

    # Necessary for using flakes on this system.
    nix.settings.experimental-features = "nix-command flakes";

    # Create /etc/zshrc that loads the nix-darwin environment.
    programs.zsh.enable = true;  # default shell on catalina
    # programs.fish.enable = true;

    # Set Git commit hash for darwin-version.
    # system.configurationRevision = self.rev or self.dirtyRev or null;

    # The platform the configuration will be used on.
    nixpkgs.hostPlatform = "aarch64-darwin";

	imports = [
		./packages.nix
		./system.nix
	];
}
