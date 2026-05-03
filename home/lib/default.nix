{ config, ... }:
{
  lib.dotfiles = {
    mkSymlinkFrom =
      dotfilesPath: relativePath:
      {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/${relativePath}";
      };
  };
}
