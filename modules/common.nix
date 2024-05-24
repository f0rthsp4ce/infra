{ pkgs, config, lib, ... }:

{
  boot.tmp = {
    useTmpfs = true;
    cleanOnBoot = true;
  };
  boot.loader.grub.configurationLimit = 5;

  services.fstrim.enable = true;

  environment.pathsToLink = [ "/share/zsh" ];

  security.sudo.wheelNeedsPassword = false;

  users.mutableUsers = false;

  time.timeZone = "Asia/Tbilisi";
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  services.earlyoom.enable = true;

  virtualisation.oci-containers.backend = "docker";

  system = {
    stateVersion = "23.05";
    autoUpgrade = {
      enable = true;
      allowReboot = false;
      flake = "github:f0rthsp4ce/infra";
      dates = "4:45";
    };
  };

  nix = {
    settings = {
      auto-optimise-store = true;
      allowed-users = [ "@users" ];
      trusted-users = [ "@wheel" ];
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://cofob.cachix.org"
        "https://f0rthsp4ce.cachix.org"
      ];
      trusted-public-keys = [
        "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cofob.cachix.org-1:pLP85fVQ2T+bbaggvq03aDdXbQWjY36Gkch14N8mus4="
        "f0rthsp4ce.cachix.org-1:9kv0K1CkG9K1NPgxNZUpN903DHCzLjg/ozZvSnHI0Dw="
      ];
    };

    daemonCPUSchedPolicy = "batch";
    daemonIOSchedPriority = 5;

    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';

    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };

    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };

  environment.systemPackages = with pkgs; [
    jq
    git
    vim
    htop
    ncdu
    tmux
    wget
    ffsend
    pastebinit
    upgrade-system
  ];

  networking.firewall.trustedInterfaces = [ "lo" ];
}
