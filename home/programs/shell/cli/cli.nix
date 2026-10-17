{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ripgrep
    bat
    tree
    eza
    fend
    fzf
    onefetch
    unzip
    zip
    wget
    bear
    pkg-config
    gum
    nmap
    mosh
    pandoc
    texlive.combined.scheme-full
    opencode
    opencode-desktop
  ];
}
