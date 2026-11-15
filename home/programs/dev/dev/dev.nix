{ pkgs, ... }:
{
  home.packages = with pkgs; [
    gnumake
    devenv
    gcc
    nodejs_24
    python312
    python312Packages.pip
    sbt
    rustc
    cargo
    rustfmt
    clippy
    beam-overlay.elixir."1.20.5"
    beam28Packages.expert
    herdr
  ];
}
