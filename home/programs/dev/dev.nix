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
    beamMinimal27Packages.elixir_1_17
  ];
}
