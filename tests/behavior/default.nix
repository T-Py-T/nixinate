{ pkgs, lib, self, repo ? ../../. }:
let
  helpers = import ./lib.nix { inherit lib pkgs; };
  args = { inherit pkgs lib self helpers repo; };
in
(import ./default-remote-buildOn.nix args)
// (import ./nixoptions-remote-rebuild.nix args)
// (import ./machine-name-dry-run-suffix.nix args)
// (import ./invalid-buildOn.nix args)
// (import ./openssh-and-tracing.nix args)
// (import ./hermetic-derivation-copy.nix args)
