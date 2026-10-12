# Checks for the nixinate package overlay (nix wrapper + nixos-rebuild wiring).
{ pkgs, lib, helpers }:
let
  inherit (helpers) assertCheck;
  nixScript = builtins.readFile "${lib.getExe pkgs.nixinate.nix}";
in
{
  overlay-nix-enables-flake-features = assertCheck "overlay-nix-enables-flake-features"
    (
      lib.hasInfix "nix-command flakes" nixScript
      && lib.hasInfix "experimental-features" nixScript
    )
    "nixinate.nix wrapper must pass nix-command and flakes experimental features";

  overlay-exposes-nixinate-attributes = assertCheck "overlay-exposes-nixinate-attributes"
    (
      (pkgs.nixinate ? nix)
      && (pkgs.nixinate ? nixos-rebuild)
    )
    "nixinate overlay should expose flake-enabled nix and nixos-rebuild attributes";
}
