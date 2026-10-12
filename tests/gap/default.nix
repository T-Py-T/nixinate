{ pkgs, lib, self }:
let
  helpers = import ./lib.nix { inherit lib pkgs; };
  args = { inherit pkgs lib self helpers; };
in
(import ./empty-and-invalid.nix args)
// (import ./remote-defaults.nix args)
// (import ./remote-nonhermetic-dry-run.nix args)
// (import ./multi-machine-local.nix args)
// (import ./app-shape.nix args)
