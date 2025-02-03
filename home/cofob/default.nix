{ pkgs, ... }:

{
  programs.home-manager.enable = true;
  home = {
    homeDirectory = "/home/cofob";
    stateVersion = "23.11";
    username = "cofob";
  };

  home.packages = with pkgs; [ vim ];
}
