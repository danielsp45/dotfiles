{ pkgs, ... }:
{
  home.packages = with pkgs; [
    gnumake
    devenv
    gcc
    clang-tools # clangd LSP + clang-format
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
    openspec
  ];
}
