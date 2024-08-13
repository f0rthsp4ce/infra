pkgs: inputs:
{
  botka-v0 = inputs.botka-v0.packages.${pkgs.system}.f0bot;
  botka-v1 = inputs.botka-v1.packages.${pkgs.system}.f0bot;
  conduit = inputs.conduit.packages.${pkgs.system}.default;
} // (import ./packages/top-level.nix { callPackage = pkgs.callPackage; })
