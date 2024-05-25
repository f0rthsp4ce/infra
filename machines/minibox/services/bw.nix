{ config, self, ... }:

{
  age.secrets.credentials-vaultwarden.file =
    "${self}/secrets/credentials/vaultwarden.age";

  services.vaultwarden = {
    enable = true;
    dbBackend = "sqlite";
    backupDir = "/var/backup/vaultwarden";
    environmentFile = config.age.secrets.credentials-vaultwarden.path;
    config = {
      domain = "https://bitwarden.f0rth.space:1337";
      signupsAllowed = true;
      rocketPort = 8222;
      rocketAddress = "127.0.0.1";
    };
  };

  services.telegram-backup.timers.hourly =
    [ config.services.vaultwarden.backupDir ];
}
