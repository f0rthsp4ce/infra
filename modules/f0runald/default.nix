{ lib, config, pkgs, ... }:

{
  options = {
    services.f0runald = {
      enable = lib.mkEnableOption "Whether to enable f0runald";
    };
  };

  config = lib.mkIf config.services.f0runald.enable {
    age.secrets.credentials-f0runald.file =
      ../../secrets/credentials/f0runald.age;

    systemd.services.f0runald-botka = {
      description = "f0runald for botka";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      path = [ pkgs.curl pkgs.python3 pkgs.docker pkgs.systemd ];
      environment.SENDER_PATH = ./sender.py;
      serviceConfig = {
        ExecStart = "${pkgs.bash}/bin/bash ${./run.sh} telegram-bot";
        Restart = "always";
        EnvironmentFile = config.age.secrets.credentials-f0runald.path;
      };
    };
  };
}
