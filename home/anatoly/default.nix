{ pkgs, ... }:

{
  programs.home-manager.enable = true;
  home = {
    homeDirectory = "/home/anatoly";
    stateVersion = "23.11";
    username = "anatoly";
  };

  home.packages = with pkgs; [ ];
}
