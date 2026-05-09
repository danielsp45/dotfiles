{ pkgs, lib, ... }:
let
  feynmanShare = "${pkgs.feynman}/share/feynman";
  feynmanVersion = pkgs.feynman.version;
in
{
  home.packages = [ pkgs.feynman ];

  # feynman writes a mutable workspace into app/.feynman/ at runtime, which
  # is incompatible with the read-only Nix store. We keep the app/ tree in a
  # writable location and re-copy it whenever the package version changes.
  home.activation.feynmanSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    FEYNMAN_DIR="$HOME/.local/share/feynman"
    VERSION_FILE="$FEYNMAN_DIR/.nix-version"

    if [ ! -f "$VERSION_FILE" ] || [ "$(cat "$VERSION_FILE" 2>/dev/null)" != "${feynmanVersion}" ]; then
      echo "Setting up feynman ${feynmanVersion}..."
      rm -rf "$FEYNMAN_DIR"
      mkdir -p "$FEYNMAN_DIR"
      cp -r ${feynmanShare}/app "$FEYNMAN_DIR/"
      chmod -R u+w "$FEYNMAN_DIR"
      echo "${feynmanVersion}" > "$VERSION_FILE"
    fi
  '';
}
