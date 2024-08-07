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

    virtualHosts."*.secure.f0rth.space" = defaults // {
      # <subdomain>-<port>-<args>.secure.f0rth.space
      # Redirects to <subdomain>.lo.f0rth.space:<port> with optional args
      #
      # Allowed args:
      # - -nph - Do not pass the X-Forwarded-Proto, X-Real-IP, and X-Forwarded-For headers
      # - -h - Use HTTPS instead of HTTP
      serverName = ''~^(?<subdomain>[a-zA-Z0-9-]+?)(-(?<port>\d+))?(-(?<args>[nph-]+))?\.secure\.f0rth\.space$'';
      extraConfig = ''
        # Local DNS resolver for dynamic domains
        resolver 127.0.0.1;

        # Include the Authelia snippets
        include ${self}/modules/nginx-snippets/authelia-upstream-minibox.conf;
        include ${self}/modules/nginx-snippets/authelia-location.conf;

        location / {
          # Include the Authelia authrequest configuration
          include ${self}/modules/nginx-snippets/authelia-authrequest.conf;

          # Set the scheme to http by default
          set $proxy_scheme http;
          # If the -h flag is specified, set the scheme to https
          if ($args ~* "-h") {
            set $proxy_scheme https;
          }

          # Set the port to an empty string by default
          set $proxy_port "";
          # If the port is specified, set it
          if ($port) {
            set $proxy_port ":$port";
          }

          # Constuct the proxy URLs
          set $proxy "$proxy_scheme://$subdomain.lo.f0rth.space$proxy_port";
          set $domain "$subdomain.lo.f0rth.space";

          # Set the Host header to the domain
          proxy_set_header Host $domain;

          # Add debug headers
          add_header X-Proxy-Host $domain;
          add_header X-Proxy-Port $proxy_port;
          add_header X-Proxy-Scheme $proxy_scheme;
          add_header X-Proxy-Subdomain $subdomain;
          add_header X-Proxy-Args $args;

          # Prepare optional headers
          set $modified_proxy_add_x_forwarded_for $proxy_add_x_forwarded_for;
          set $modified_scheme $scheme;
          set $modified_remote_addr $remote_addr;
          if ($args ~* "-nph") {
            set $modified_proxy_add_x_forwarded_for "";
            set $modified_scheme "";
            set $modified_remote_addr "";
          }

          # Add optional headers
          proxy_set_header X-Forwarded-For $modified_proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $modified_scheme;
          proxy_set_header X-Real-IP $modified_remote_addr;

          # Allow the use of WebSockets
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";
          proxy_read_timeout 86400;

          # Proxy the request to the target
          proxy_pass $proxy;
        }
      '';
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
