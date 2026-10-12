# Configuration that will be added to both the nixinatee node and the nixinator
# node.
{ inputs }:
{
  boot.loader.grub.enable = false;
  documentation.enable = false;
  system.stateVersion = "24.11";

  nix = {
    extraOptions =
      let
        empty_registry = builtins.toFile "empty-flake-registry.json" ''{"flakes":[],"version":2}'';
      in
      ''
        experimental-features = nix-command flakes
        flake-registry = ${empty_registry}
      '';
    registry.nixpkgs.flake = inputs.nixpkgs;
  };
}
