{ config, home-manager, cofob-home, ... }:

let user-keys = import ../ssh-keys.nix;
in {
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.cofob = cofob-home.nixosModules.home-headless;
  home-manager.users.def = import ../home/def;
  home-manager.users.tar = import ../home/tar;
  home-manager.users.mike = import ../home/mike;

  age.secrets.password-root.file = ../secrets/passwords/root.age;
  age.secrets.password-cofob.file = ../secrets/passwords/cofob.age;
  age.secrets.password-def.file = ../secrets/passwords/def.age;
  age.secrets.password-tar.file = ../secrets/passwords/tar.age;
  age.secrets.password-mike.file = ../secrets/passwords/mike.age;

  users = {
    users = {
      root.hashedPasswordFile = config.age.secrets.password-root.path;
      cofob = {
        isNormalUser = true;
        description = "Egor Ternovoy";
        extraGroups = [ "wheel" "pipewire" ];
        uid = 1001;
        hashedPasswordFile = config.age.secrets.password-cofob.path;
        openssh.authorizedKeys.keys = user-keys.cofob;
      };
      def = {
        isNormalUser = true;
        description = "Dettlaff";
        extraGroups = [ "wheel" "pipewire" ];
        uid = 1002;
        hashedPasswordFile = config.age.secrets.password-def.path;
        openssh.authorizedKeys.keys = user-keys.dettlaff;
      };
      tar = {
        isNormalUser = true;
        description = "tar";
        extraGroups = [ "wheel" ];
        uid = 1003;
        hashedPasswordFile = config.age.secrets.password-tar.path;
        openssh.authorizedKeys.keys = user-keys.tar-xzf;
      };
      mike = {
        isNormalUser = true;
        description = "Mike";
        extraGroups = [ "wheel" ];
        uid = 1004;
        hashedPasswordFile = config.age.secrets.password-mike.path;
        openssh.authorizedKeys.keys = user-keys.mike;
      };
    };
  };
}
