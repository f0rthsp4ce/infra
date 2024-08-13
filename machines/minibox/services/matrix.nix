{ config, self, pkgs, lib, ... }:

let db = "postgres:///dendrite?host=/run/postgresql";
in {
  age.secrets.credentials-dendrite-private-key.file =
    "${self}/secrets/credentials/dendrite-private-key.age";
  age.secrets.credentials-dendrite-private-key.mode = "777";
  age.secrets.credentials-dendrite-ldap-password.file =
    "${self}/secrets/credentials/dendrite-ldap-password.age";
  age.secrets.credentials-dendrite-ldap-password.mode = "777";
  age.secrets.credentials-dendrite-turn-secret.file =
    "${self}/secrets/credentials/dendrite-turn-secret.age";
  age.secrets.credentials-dendrite-turn-secret.mode = "777";
  age.secrets.credentials-dendrite-mautrix-telegram.file =
    "${self}/secrets/credentials/dendrite-mautrix-telegram.age";
  age.secrets.credentials-dendrite-mautrix-telegram.mode = "777";

  # Matrix server (Dendrite)
  services.dendrite = {
    enable = true;
    httpPort = 8008;
    loadCredential = [
      "private_key:${config.age.secrets.credentials-dendrite-private-key.path}"
      "ldap_password:${config.age.secrets.credentials-dendrite-ldap-password.path}"
      "turn_secret:${config.age.secrets.credentials-dendrite-turn-secret.path}"
    ];
    settings = {
      global.server_name = "f0rth.space";
      global.private_key = "$CREDENTIALS_DIRECTORY/private_key";
      global.database.max_open_conns = 20;
      user_api.device_database.connection_string = db;
      user_api.account_database.connection_string = db;
      sync_api.search.enable = true;
      sync_api.database.connection_string = db;
      settings.room_server.database.connection_string = db;
      relay_api.database.connection_string = db;
      mscs.database.connection_string = db;
      media_api.database.connection_string = db;
      key_server.database.connection_string = db;
      federation_api.database.connection_string = db;
      app_service_api = {
        database.connection_string = db;
        config_files = [
          "${config.age.secrets.credentials-dendrite-mautrix-telegram.path}"
        ];
      };
      client_api.turn = {
        turn_user_lifetime = "5m";
        turn_uris = [
          "turn:turn.f0rth.space?transport=udp"
          "turn:turn.f0rth.space?transport=tcp"
        ];
        turn_shared_secret = "$CREDENTIALS_DIRECTORY/turn_secret";
      };
      ldap = {
        enabled = true;
        uri = "ldap://ldap.lo.f0rth.space:389";
        base_dn = "dc=f0rth,dc=space";
        admin_bind_enabled = true;
        admin_bind_dn = "cn=admin,dc=f0rth,dc=space";
        admin_bind_password = "$CREDENTIALS_DIRECTORY/ldap_password";
        search_base_dn = "ou=users,dc=f0rth,dc=space";
        search_filter = "(&(objectclass=customPerson)(cn={username}))";
        search_attribute = "cn";
      };
    };
  };

  # Matrix bridge
  age.secrets.credentials-mautrix-telegram-config.file =
    "${self}/secrets/credentials/mautrix-telegram-config.age";
  services.mautrix-telegram = {
    enable = true;

    environmentFile =
      config.age.secrets.credentials-mautrix-telegram-config.path;

    settings = {
      homeserver = {
        address = "http://localhost:8008";
        domain = "f0rth.space";
      };
      appservice = {
        id = "telegram";
        database = "postgresql:///mautrix-telegram?host=/run/postgresql";
      };
      bridge = {
        displayname_template = "{displayname}";
        delivery_receipts = true;
        pinned_tag = "m.favourite";
        archive_tag = "m.lowpriority";
        relaybot.authless_portals = false;
        encryption.allow = true;

        message_formats = {
          "m.text" = "<b>$sender_displayname</b>:<br/>$message";
          "m.notice" = "<b>$sender_displayname</b>:<br/>$message";
          "m.emote" = "* <b>$sender_displayname</b> $message";
          "m.file" = "<b>$sender_displayname</b> sent a file:<br/>$message";
          "m.image" = "<b>$sender_displayname</b> sent an image:<br/>$message";
          "m.audio" =
            "<b>$sender_displayname</b> sent an audio file:<br/>$message";
          "m.video" = "<b>$sender_displayname</b> sent a video:<br/>$message";
          "m.location" =
            "<b>$sender_displayname</b> sent a location:<br/>$message";
        };
        state_event_formats = {
          join = "";
          leave = "";
          name_change = "";
        };

        permissions = {
          "*" = "relaybot";
          "f0rth.space" = "full";
          "@i:f0rth.space" = "admin";
        };

        animated_sticker = {
          target = "gif";
          args = {
            width = 256;
            height = 256;
            fps = 30; # only for webm
            background = "020202"; # only for gif, transparency not supported
          };
        };
      };
    };
  };

  systemd.services.mautrix-telegram.path = with pkgs; [
    lottieconverter # for animated stickers conversion, unfree package
    ffmpeg # if converting animated stickers to webm (very slow!)
  ];

  # TURN server
  age.secrets.credentials-coturn-secret.file =
    "${self}/secrets/credentials/coturn-secret.age";
  age.secrets.credentials-coturn-secret.owner = "turnserver";
  age.secrets.credentials-coturn-secret.group = "turnserver";
  services.coturn = {
    enable = true;
    use-auth-secret = true;
    static-auth-secret-file = config.age.secrets.credentials-coturn-secret.path;
    realm = "turn.f0rth.space";
    cert =
      "${config.security.acme.certs."f0rth.space".directory}/fullchain.pem";
    pkey = "${config.security.acme.certs."f0rth.space".directory}/privkey.pem";
    extraConfig = ''
      # don't let the relay ever try to connect to private IP address ranges within your network (if any)
      # given the turn server is likely behind your firewall, remember to include any privileged public IPs too.
      denied-peer-ip=10.0.0.0-10.255.255.255
      denied-peer-ip=192.168.0.0-192.168.255.255
      denied-peer-ip=172.16.0.0-172.31.255.255

      # recommended additional local peers to block, to mitigate external access to internal services.
      # https://www.rtcsec.com/article/slack-webrtc-turn-compromise-and-bug-bounty/#how-to-fix-an-open-turn-relay-to-address-this-vulnerability
      no-multicast-peers
      denied-peer-ip=0.0.0.0-0.255.255.255
      denied-peer-ip=100.64.0.0-100.127.255.255
      denied-peer-ip=127.0.0.0-127.255.255.255
      denied-peer-ip=169.254.0.0-169.254.255.255
      denied-peer-ip=192.0.0.0-192.0.0.255
      denied-peer-ip=192.0.2.0-192.0.2.255
      denied-peer-ip=192.88.99.0-192.88.99.255
      denied-peer-ip=198.18.0.0-198.19.255.255
      denied-peer-ip=198.51.100.0-198.51.100.255
      denied-peer-ip=203.0.113.0-203.0.113.255
      denied-peer-ip=240.0.0.0-255.255.255.255

      # consider whether you want to limit the quota of relayed streams per user (or total) to avoid risk of DoS.
      user-quota=12 # 4 streams per video call, so 12 streams = 3 simultaneous relayed calls per user.
      total-quota=1200
    '';
  };

  security.acme.certs."f0rth.space".reloadServices = [ "coturn" ];

  networking.firewall.allowedTCPPorts = [ 3478 5349 ];
  networking.firewall.allowedUDPPorts = [ 3478 5349 ];

  services.proxmox-backup.jobs.daily.paths = [{
    name = "mautrix-telegram";
    path = "/var/lib/mautrix-telegram";
  }];
}
