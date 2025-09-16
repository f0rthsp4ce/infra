{ pkgs, ... }:

{
  programs.home-manager.enable = true;
  home = {
    homeDirectory = "/home/skywinder";
    stateVersion = "23.11";
    username = "skywinder";
  };

  home.packages = with pkgs; [ ];
}
