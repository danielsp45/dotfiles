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
    elixir-bin."1.17.3"
    beam28Packages.expert
  ];
}
