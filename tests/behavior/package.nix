# Standalone driver: build every behavior check without extending flake.checks.
# Usage (from repo root): nix build -L -f tests/behavior/package.nix --no-link
{ repo ? ../../. }:
let
  flake = builtins.getFlake (toString repo);
  system = builtins.currentSystem;
  pkgs = import flake.inputs.nixpkgs {
    inherit system;
    overlays = [ flake.overlay ];
  };
  lib = pkgs.lib;
  tests = import ./default.nix {
    inherit pkgs lib;
    self = flake;
    repo = toString repo;
  };
in
pkgs.linkFarm "nixinate-behavior-checks"
  (lib.mapAttrsToList (name: path: { inherit name path; }) tests)
