{ pkgs, lib, ... }:
let
  zoteroAgentXpi = pkgs.fetchurl {
    url = "https://github.com/54yyyu/zotero-mcp/releases/download/v0.14.1/zotero-agent.xpi";
    hash = "sha256-yvujilmN7Pz++IUhSWNX7NMQyBtL88wIXTTIGrNDfd4=";
  };
in
{
  home.packages = [ pkgs.uv ];

  home.activation.zoteroMcpSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "$HOME/.local/bin/zotero-mcp" ]; then
      echo "Installing zotero-mcp-server..."
      ${pkgs.uv}/bin/uv tool install zotero-mcp-server
    fi

    if [ ! -f "$HOME/.claude/skills/zotero-cli" ]; then
      echo "Installing zotero-mcp skill for Claude Code..."
      "$HOME/.local/bin/zotero-mcp" install-skill
    fi

    mkdir -p "$HOME/.local/share/zotero-mcp"
    cp --no-preserve=all ${zoteroAgentXpi} "$HOME/.local/share/zotero-mcp/zotero-agent.xpi"
  '';
}
