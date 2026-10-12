{ pkgs, lib, self }:
let
  helpers = import ./lib.nix { inherit lib pkgs; };
  evalTests = import ./generateApps-eval.nix { inherit pkgs lib self helpers; };
  scriptTests = import ./deploy-scripts.nix { inherit pkgs lib self helpers; };
  overlayTests = import ./overlay.nix { inherit pkgs lib helpers; };
in
evalTests // scriptTests // overlayTests
