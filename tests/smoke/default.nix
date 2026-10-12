{ pkgs, lib, self, repo ? ../../. }:
let
  helpers = import ./lib.nix { inherit lib pkgs; };
  args = { inherit pkgs lib self helpers; };
in
  (import ./flake-outputs.nix (args // { inherit repo; }))
  // (import ./option-defaults.nix args)
  // (import ./local-buildon-options.nix args)
  // (import ./mixed-fleet.nix args)
  // (import ./deploy-script-structure.nix args)
