{ config, pkgs, lib, ... }:

let
  # Where your dotfiles live on disk (change if needed)
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  oos = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";

in {
  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # --- Editors / IDEs ---
    neovim

    # --- CLI utilities ---
    ripgrep
    lazygit
    git
    bat
    btop
    neofetch
    fastfetch
    tree
    direnv
    eza
    fend
    onefetch
    unzip
    zip
    wget
    tmux
    bear
    pkg-config

    # --- Build / Development tools ---
		gnumake
    devenv
    gcc
		nodejs_24
    python312
    python312Packages.pip
    sbt
		starship
		fzf
		direnv
		rustup
    beamMinimal27Packages.elixir_1_17
		nix-direnv
    gum

    # --- Fonts / Typesetting ---
    typst
    roboto
    source-sans-pro
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  # home.file = {
  #   ".config/nvim".source = ./../nvim;
  #   ".tmux.conf".source = ./../tmux/tmux.conf;
  #   ".config/fastfetch".source = ./../fastfetch;
  #   ".gitconfig".source = ./../git/gitconfig;
  # };
  home.file = {
    ".config/nvim".source = oos "nvim";
    ".tmux.conf".source = oos "tmux/tmux.conf";
    ".config/fastfetch".source = oos "fastfetch";
    ".gitconfig".source = oos "git/gitconfig";
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
