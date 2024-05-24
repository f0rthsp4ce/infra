{ pkgs, ... }:

{
  programs.home-manager.enable = true;
  home = {
    homeDirectory = "/home/def";
    stateVersion = "23.11";
    username = "def";
  };

  home.packages = with pkgs; [ micro neofetch ];
}
