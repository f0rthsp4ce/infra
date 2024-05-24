{ pkgs, lib, ... }:

{
  services.openssh = {
    enable = true;
    openFirewall = lib.mkDefault true;
    settings.PermitRootLogin = "no";
    settings.PasswordAuthentication = false;
  };
}
