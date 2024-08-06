{ config, pkgs, self, ... }:

let
  defaults = {
    quic = true;
    http3 = true;
    kTLS = true;
    forceSSL = true;
    sslCertificate =
      "${config.security.acme.certs."f0rth.space".directory}/fullchain.pem";
    sslCertificateKey =
      "${config.security.acme.certs."f0rth.space".directory}/key.pem";
  };

  # public = {
  #   listen = [{
  #     addr = "0.0.0.0";
  #     port = 1337;
  #     ssl = true;
  #   }];
  # };
in {
  users.users.cloudflared = {
    group = "cloudflared";
    isSystemUser = true;
  };
  users.groups.cloudflared = { };

  age.secrets.credentials-minibox-cloudflared.file =
    "${self}/secrets/credentials/minibox-cloudflared.age";
  systemd.services.cloudflared = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    path = [ pkgs.cloudflared ];
    serviceConfig = {
      ExecStart = pkgs.writeShellScript "cloudflared-service" ''
        cloudflared tunnel run --token=$TOKEN
      '';
      EnvironmentFile = config.age.secrets.credentials-minibox-cloudflared.path;
      Restart = "always";
      User = "cloudflared";
      Group = "cloudflared";
    };
  };

  services.nginx = {
    enable = true;

    virtualHosts."minibox-portainer.lo.f0rth.space" = defaults // {
      locations."/".proxyPass = "https://127.0.0.1:9443";
    };

    virtualHosts."bitwarden.lo.f0rth.space" = defaults // {
      locations."/".proxyPass = "http://127.0.0.1:8222";
    };

    virtualHosts."grafana.lo.f0rth.space" = defaults // {
      locations."/".proxyPass = "http://127.0.0.1:3001";
    };

    virtualHosts."prometheus.lo.f0rth.space" = defaults // {
      locations."/".proxyPass = "http://127.0.0.1:9090";
    };

    virtualHosts."ha.lo.f0rth.space" = defaults // {
      locations."/" = {
        proxyPass = "http://ha-direct.lo.f0rth.space:8123";
        proxyWebsockets = true;
      };
    };

    virtualHosts."homeassistant.lo.f0rth.space" = defaults // {
      globalRedirect = "ha.lo.f0rth.space";
    };

    # virtualHosts."wiki.f0rth.space" = defaults // public // {
    #   locations."/".proxyPass = "http://127.0.0.1:3000";
    # };
  };

  networking.firewall = {
    allowedTCPPorts = [ 80 443 ];
    allowedUDPPorts = [ 443 ];
  };
}
