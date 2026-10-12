# Standalone driver for gap-coverage checks (does not extend flake.checks).
# Usage (from repo root): nix build -L -f tests/gap/package.nix --no-link
{ repo ? ../../. }:
let
  flake = builtins.getFlake (toString repo);
  system = builtins.currentSystem;
  pkgs = import flake.inputs.nixpkgs {
    inherit system;
    overlays = [ flake.overlay ];
  };
  lib = pkgs.lib;
  tests = import ./default.nix { inherit pkgs lib; self = flake; };
in
pkgs.linkFarm "nixinate-gap-checks"
  (lib.mapAttrsToList (name: path: { inherit name path; }) tests)
