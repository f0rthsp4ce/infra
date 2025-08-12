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
    validateConfigFile = false;

    virtualHosts."not_found" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 80;
          extraParameters = [ "default_server" ];
        }
        {
          addr = "[::0]";
          port = 80;
          extraParameters = [ "default_server" ];
        }
        {
          addr = "0.0.0.0";
          port = 443;
          ssl = true;
          extraParameters = [ "default_server" ];
        }
        {
          addr = "[::0]";
          port = 443;
          ssl = true;
          extraParameters = [ "default_server" ];
        }
        {
          addr = "0.0.0.0";
          port = 443;
          extraParameters = [ "quic" "default_server" ];
        }
        {
          addr = "[::0]";
          port = 443;
          extraParameters = [ "quic" "default_server" ];
        }
      ];
      serverName = "_";
      extraConfig = ''
        http2 on;
        http3 on;
        http3_hq off;
        ssl_certificate "${
          config.security.acme.certs."f0rth.space".directory
        }/fullchain.pem";
        ssl_certificate_key "${
          config.security.acme.certs."f0rth.space".directory
        }/key.pem";
        return 301 https://f0rth.space/not_found.html;
      '';
    };

    virtualHosts."minibox-portainer.lo.f0rth.space" = defaults // {
      locations."/".proxyPass = "https://127.0.0.1:9443";
    };

    virtualHosts."bitwarden.lo.f0rth.space" = defaults // {
      locations."/".proxyPass = "http://127.0.0.1:8222";
    };

    virtualHosts."grafana.lo.f0rth.space" = defaults // {
      locations."/".proxyPass = "http://127.0.0.1:3001";
      extraConfig = ''
        add_header Content-Security-Policy "default-src 'self'; connect-src 'self' https://grafana.f0rth.space;";
      '';
    };

    virtualHosts."prometheus.lo.f0rth.space" = defaults // {
      locations."/".proxyPass = "http://127.0.0.1:9090";
    };

    virtualHosts."ha.lo.f0rth.space" = defaults // {
      locations."/" = {
        recommendedProxySettings = false;
        proxyPass = "http://ha-direct.lo.f0rth.space:8123";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header        Host $host;
          proxy_set_header        X-Real-IP $remote_addr;
          # Home Assistant doesn't work correctly with the X-Forwarded-Proto header
          # proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header        X-Forwarded-Proto $scheme;
          proxy_set_header        X-Forwarded-Host $host;
          proxy_set_header        X-Forwarded-Server $host;
        '';
      };
    };

    virtualHosts."homeassistant.lo.f0rth.space" = defaults // {
      globalRedirect = "ha.lo.f0rth.space";
    };

    virtualHosts."ldapadmin.lo.f0rth.space" = defaults // {
      locations."/".proxyPass = "https://localhost:6443";
    };

    virtualHosts."conncheck.lo.f0rth.space" = defaults // {
      locations."/".return = "200 ok";
      extraConfig = ''
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE' always;
        add_header 'Access-Control-Allow-Headers' '*' always;

        # Preflight requests
        if ($request_method = OPTIONS) {
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE' always;
            add_header 'Access-Control-Allow-Headers' '*' always;
            add_header 'Access-Control-Max-Age' 3600;
            return 204;
        }

        # --- Content Security Policy: Allow everything ---
        add_header Content-Security-Policy "default-src * 'unsafe-inline' 'unsafe-eval' data: blob:;" always;
      '';
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 80 443 ];
    allowedUDPPorts = [ 443 ];
  };
  # Allow requests to proxy protocol listen from proxy
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 8443 ];
}
