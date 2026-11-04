{ pkgs, mkSymlink, ... }:
{
  home.packages = [ pkgs.claude-code ];
  home.file.".claude/commands" = mkSymlink "commands";
}
