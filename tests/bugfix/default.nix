# Regression checks for generateApps edge cases (no VMs).
{ pkgs, self }:
let
  lib = pkgs.lib;
  system = pkgs.hostPlatform.system;
  generateApps = self.nixinate.${system};

  mkFlake = configs: {
    outPath = "/mock/nixinate-bugfix-flake";
    nixosConfigurations = configs;
  };

  deployScript = flake: machine:
    builtins.readFile (generateApps flake).nixinate.${machine}.program;

  assertCheck = name: condition: message:
    pkgs.runCommand "bugfix-${name}" { } ''
      if ${lib.boolToString condition}; then
        touch $out
      else
        echo "${message}" >&2
        exit 1
      fi
    '';

  remoteNonHermeticFlake = mkFlake {
    edge = {
      _module.args.nixinate = {
        host = "edge.example.net";
        buildOn = "remote";
        hermetic = false;
        nixOptions = [ "--option" "connect-timeout" "12" ];
      };
    };
  };

  remoteNonHermeticScript = deployScript remoteNonHermeticFlake "edge";

  mixedModuleFlake = mkFlake {
    deployable = {
      _module.args.nixinate = {
        host = "deployable.internal";
        buildOn = "local";
      };
    };
    legacy = { };
    other = { _module.args = { }; };
  };

  mixedApps = (generateApps mixedModuleFlake).nixinate;
in
{
  remote-nonhermetic-nixoptions-on-rebuild =
    assertCheck "remote-nonhermetic-nixoptions-on-rebuild"
      (
        lib.hasInfix "nixos-rebuild --option connect-timeout 12 switch" remoteNonHermeticScript
        && lib.hasInfix "--option connect-timeout 12 copy" remoteNonHermeticScript
      )
      "remote non-hermetic deploy must pass nixOptions to both nix copy and the remote nixos-rebuild SSH command";

  skip-configs-without-module =
    assertCheck "skip-configs-without-module"
      (
        mixedApps ? deployable
        && mixedApps ? "deployable-dry-run"
        && !(mixedApps ? legacy)
        && !(mixedApps ? other)
        && builtins.length (builtins.attrNames mixedApps) == 2
      )
      "generateApps should ignore nixosConfigurations without _module.args.nixinate instead of failing evaluation";
}
