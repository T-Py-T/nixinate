{
  description = "Pinned Nix tooling for CI dependency audits (isolated from the root flake to avoid conflicting with open readiness PRs).";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        packages.default = pkgs.writeShellScriptBin "flake-audit" ''
          set -euo pipefail
          ${pkgs.jq}/bin/jq --version
          ${pkgs.nix}/bin/nix --version
        '';

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ jq nix bash ];
        };
      });
}
