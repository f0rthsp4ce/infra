pkgs: inputs:
{
  botka-v0 = inputs.botka-v0.packages.x86_64-linux.f0bot;
  botka-v1 = inputs.botka-v1.packages.x86_64-linux.f0bot;
} // (import ./packages/top-level.nix { callPackage = pkgs.callPackage; })
