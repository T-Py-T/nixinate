# Standalone driver: build every fast check without extending flake.checks.
# Usage (from repo root): nix build -f tests/fast/package.nix
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
pkgs.linkFarm "nixinate-fast-checks"
  (lib.mapAttrsToList (name: path: { inherit name path; }) tests)
