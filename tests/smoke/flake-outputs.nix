# Regression checks for exported flake metadata and per-system nixinate apps.
{ pkgs, lib, self, helpers, repo ? ../../. }:
let
  inherit (helpers) assertCheck;
  supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
  flakeMeta = import (repo + "/flake.nix");
in
{
  smoke-flake-has-description = assertCheck "flake-has-description"
    (builtins.isString flakeMeta.description && lib.hasInfix "Nixinate" flakeMeta.description)
    "flake description should identify the project";

  smoke-hercules-ci-systems-linux-only = assertCheck "hercules-ci-systems-linux-only"
    (self.herculesCI.ciSystems == [ "x86_64-linux" ])
    "herculesCI.ciSystems should list only x86_64-linux for VM checks";

  smoke-nixinate-on-all-supported-systems = assertCheck "nixinate-on-all-supported-systems"
    (
      lib.all
        (system:
          builtins.hasAttr system self.nixinate
          && builtins.isFunction self.nixinate.${system}
        )
        supportedSystems
    )
    "flake should expose nixinate.<system> generateApps for every supported system";

  smoke-overlay-provides-nixinate = assertCheck "overlay-provides-nixinate"
    (builtins.isFunction self.overlay)
    "flake overlay should be a function for nixpkgs imports";
}
