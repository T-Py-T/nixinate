# Standalone driver: build every smoke check without extending flake.checks.
# Usage (from repo root): nix build -L -f tests/smoke/package.nix --no-link
{ repo ? ../../. }:
let
  flake = builtins.getFlake (toString repo);
  system = builtins.currentSystem;
  pkgs = import flake.inputs.nixpkgs {
    inherit system;
    overlays = [ flake.overlay ];
  };
  lib = pkgs.lib;
  tests = import ./default.nix { inherit pkgs lib repo; self = flake; };
in
pkgs.linkFarm "nixinate-smoke-checks"
  (lib.mapAttrsToList (name: path: { inherit name path; }) tests)
