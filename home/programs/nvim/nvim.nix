{ pkgs, mkSymlink, ... }:
{
  home.packages = [ pkgs.neovim ];
  home.sessionVariables.EDITOR = "nvim";
  xdg.configFile."nvim/init.lua" = mkSymlink "init.lua";
  xdg.configFile."nvim/lazy-lock.json" = mkSymlink "lazy-lock.json";
  xdg.configFile."nvim/lua" = mkSymlink "lua";
}
