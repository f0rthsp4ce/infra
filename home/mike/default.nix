{ pkgs, ... }:

{
  programs.home-manager.enable = true;
  home = {
    homeDirectory = "/home/mike";
    stateVersion = "23.11";
    username = "mike";
  };

  home.packages = with pkgs; [ ];
}
