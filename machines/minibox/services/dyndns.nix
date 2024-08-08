{ self, config, pkgs, ... }:

{
  age.secrets.credentials-dyndns-cloudflare.file =
    "${self}/secrets/credentials/dyndns-cloudflare.age";

  users.users.dyndns-cloudflare = {
    isSystemUser = true;
    group = "dyndns-cloudflare";
  };
  users.groups.dyndns-cloudflare = { };

  systemd.services.dyndns-cloudflare = {
    description = "Dynamic DNS updater for Cloudflare";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    environment.PYTHONUNBUFFERED = "1";
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.dyndns-cloudflare}/bin/dyndns-cloudflare";
      Restart = "always";
      RestartSec = "5";
      User = "dyndns-cloudflare";
      Group = "dyndns-cloudflare";
      EnvironmentFile = config.age.secrets.credentials-dyndns-cloudflare.path;
    };
  };
}
