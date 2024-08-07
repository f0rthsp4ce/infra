{ config, self, pkgs, ... }:

{
  users.users.f0rthsp4ce-bot = {
    isSystemUser = true;
    description = "f0rthsp4ce bot user";
    home = "/var/lib/f0rthsp4ce-bot";
    createHome = true;
    group = "f0rthsp4ce-bot";
  };
  users.groups.f0rthsp4ce-bot = { };

  age.secrets.credentials-botka-v0.file =
    "${self}/secrets/credentials/botka-v0.age";
  age.secrets.credentials-botka-v0.owner = "f0rthsp4ce-bot";
  age.secrets.credentials-botka-v0.group = "f0rthsp4ce-bot";
  systemd.services.f0rthsp4ce-bot-v0 = {
    description = "f0rthsp4ce telegram bot";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    environment = {
      TZ = "Asia/Tbilisi";
      RUST_BACKTRACE = "1";
    };
    serviceConfig = {
      ExecStart =
        "${pkgs.botka-v0}/bin/f0bot bot ${config.age.secrets.credentials-botka-v0.path}";
      KillSignal = "SIGINT"; # freaking tokio::ctrl_c handler
      WorkingDirectory = "/var/lib/f0rthsp4ce-bot/v0";
      User = "f0rthsp4ce-bot";
      Group = "f0rthsp4ce-bot";
      Restart = "on-failure";
    };
  };

  age.secrets.credentials-botka-v1.file =
    "${self}/secrets/credentials/botka-v1.age";
  age.secrets.credentials-botka-v1.owner = "f0rthsp4ce-bot";
  age.secrets.credentials-botka-v1.group = "f0rthsp4ce-bot";
  systemd.services.f0rthsp4ce-bot-v1 = {
    description = "f0rthsp4ce telegram bot";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    environment = {
      TZ = "Asia/Tbilisi";
      RUST_BACKTRACE = "1";
    };
    serviceConfig = {
      ExecStart =
        "${pkgs.botka-v1}/bin/f0bot bot ${config.age.secrets.credentials-botka-v1.path}";
      KillSignal = "SIGINT"; # freaking tokio::ctrl_c handler
      WorkingDirectory = "/var/lib/f0rthsp4ce-bot/v1";
      User = "f0rthsp4ce-bot";
      Group = "f0rthsp4ce-bot";
      Restart = "on-failure";
    };
  };

  networking.firewall.allowedTCPPorts = [
    42777 # v1
    42776 # v0
  ];

  services.proxmox-backup.jobs.daily.paths = [{
    name = "f0rthsp4ce-bot";
    path = "/var/lib/f0rthsp4ce-bot";
  }];
}
