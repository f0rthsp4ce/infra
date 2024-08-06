{ self, config, ... }:

{
  imports = [
    ./services

    "${self}/modules"
    "${self}/hardware/vmbox.nix"
  ];

  custom.backup-defaults.enable = true;

  networking.firewall.allowedTCPPorts = [
    22 # ssh
  ];

  networking = {
    hostName = "vmbox";
    networkmanager.enable = true;
  };
}
