{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

stdenv.mkDerivation rec {
  pname = "feynman";
  version = "0.2.43";

  src = fetchurl {
    url = "https://github.com/getcompanion-ai/feynman/releases/download/v${version}/feynman-${version}-linux-x64.tar.gz";
    hash = "sha256-qzaoobHkjIykJX9PGeH/a2LX6EERt/5HGbUk9RzU2vY=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  # Bundled node binary links against libstdc++
  buildInputs = [ stdenv.cc.cc.lib ];

  # The bundled node_modules include a musl-variant clipboard library that we
  # will never load on glibc Linux — skip patching it rather than failing.
  autoPatchelfIgnoreMissingDeps = [ "libc.musl-x86_64.so.1" ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/feynman $out/bin
    cp -r node app $out/share/feynman/

    # The wrapper calls the patched node from the store, but the app runs from
    # ~/.local/share/feynman/app/ (a writable copy managed by home-manager
    # activation) so that feynman can write its workspace to app/.feynman/.
    cat > $out/bin/feynman << EOF
    #!/bin/sh
    exec $out/share/feynman/node/bin/node "\$HOME/.local/share/feynman/app/bin/feynman.js" "\$@"
    EOF
    chmod +x $out/bin/feynman

    runHook postInstall
  '';

  meta = {
    description = "Feynman AI coding assistant";
    homepage = "https://feynman.is";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "feynman";
  };
}
