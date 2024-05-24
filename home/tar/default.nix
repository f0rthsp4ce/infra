{ pkgs, ... }:

{
  programs.home-manager.enable = true;
  home = {
    homeDirectory = "/home/tar";
    stateVersion = "23.11";
    username = "tar";
  };

  home.packages = with pkgs; [ neovim ripgrep ];
}
