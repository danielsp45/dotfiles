{ config, pkgs, ... }:

{
    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    home.stateVersion = "24.05"; # Please read the comment before changing.

    # The home.packages option allows you to install Nix packages into your
    # environment.
    home.packages = [
        pkgs.zsh
        pkgs.zsh-z
        pkgs.oh-my-zsh
        pkgs.zsh-powerlevel10k
        pkgs.neovim
        pkgs.ripgrep
        pkgs.lazygit
        pkgs.git
        pkgs.bat
        pkgs.btop
        pkgs.neofetch
        pkgs.thefuck
        pkgs.tree
        pkgs.direnv
        pkgs.eza
		pkgs.fend
		pkgs.cmake
		pkgs.onefetch
		pkgs.devenv
		pkgs.unzip
		pkgs.gcc
    ];

    # Home Manager is pretty good at managing dotfiles. The primary way to manage
    # plain files is through 'home.file'.
    home.file = {
      ".config/nvim".source = ./../nvim;
    };

    home.sessionVariables = {
      EDITOR = "nvim";
    };


    # Home Manager can also manage your environment variables through
    # 'home.sessionVariables'. These will be explicitly sourced when using a
    # shell provided by Home Manager. If you don't want to manage your shell
    # through Home Manager then you have to manually source 'hm-session-vars.sh'
    # located at either
    #
    #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
    #
    # or
    #
    #
    # or
    #
    #  /etc/profiles/per-user/danielsp_45/etc/profile.d/hm-session-vars.sh
    #
    # Let Home Manager install and manage itself.
    programs.home-manager.enable = true;
}
