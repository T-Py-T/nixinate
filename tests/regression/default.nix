# Fast regression checks for deploy tooling (no VMs).
{ pkgs, self }:
let
  lib = pkgs.lib;
  system = pkgs.hostPlatform.system;
  generateApps = self.nixinate.${system};

  mkFlake = cfg: {
    outPath = "/fake/nixinate-regression-flake";
    nixosConfigurations.machine = { _module.args.nixinate = cfg; };
  };

  readDeployScript = flake: machine:
    let apps = generateApps flake;
    in builtins.readFile apps.nixinate.${machine}.program;

  wrappedNix = lib.getExe pkgs.nixinate.nix;
  defaultNix = lib.getExe pkgs.nix;

  remoteHermeticScript = readDeployScript (mkFlake {
    host = "remote.example.com";
    buildOn = "remote";
    hermetic = true;
  }) "machine";

  # Store paths cannot appear in regex strings; compare as plain strings.
  contains = needle: haystack:
    lib.hasInfix
      (builtins.unsafeDiscardStringContext needle)
      (builtins.unsafeDiscardStringContext haystack);
in
{
  deployUsesWrappedNix =
    assert defaultNix != wrappedNix;
    assert contains wrappedNix remoteHermeticScript;
    assert !(contains defaultNix remoteHermeticScript);
    pkgs.runCommand "regression-deploy-uses-wrapped-nix" { } "touch $out";

  nixosRebuildUsesWrappedNix =
    assert pkgs.nixinate.nixos-rebuild.drvPath != pkgs.nixos-rebuild.drvPath;
    pkgs.runCommand "regression-nixos-rebuild-uses-wrapped-nix" { } "touch $out";
}
