pkgs:

{
  upgrade-system = pkgs.callPackage ./upgrade-system.nix { };
  nginx = (pkgs.callPackage ./nginx.nix { });
}
