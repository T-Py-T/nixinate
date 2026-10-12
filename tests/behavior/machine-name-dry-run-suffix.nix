# Machine names ending in "-dry-run" must not confuse dry-run app name resolution.
{ pkgs, lib, self, helpers, ... }:
let
  inherit (helpers) assertCheck mkFlake deployScript dryRunScript;
  system = pkgs.hostPlatform.system;
  generateApps = self.nixinate.${system};

  flake = mkFlake {
    "api-dry-run" = {
      _module.args.nixinate = {
        host = "api.example";
        buildOn = "remote";
        hermetic = false;
      };
    };
  };

  apps = generateApps flake;
  normal = deployScript { inherit generateApps; flake = flake; machine = "api-dry-run"; };
  dry = dryRunScript { inherit generateApps; flake = flake; machine = "api-dry-run"; };

in
{
  behavior-hyphenated-machine-gets-both-apps = assertCheck "hyphenated-machine-gets-both-apps"
    (
      (apps.nixinate ? "api-dry-run")
      && (apps.nixinate ? "api-dry-run-dry-run")
    )
    "machine api-dry-run should expose deploy and api-dry-run-dry-run apps";

  behavior-hyphenated-dry-run-targets-same-machine = assertCheck "hyphenated-dry-run-targets-same-machine"
    (
      lib.hasInfix "nixosConfigurations.api-dry-run" normal
      && lib.hasInfix "nixosConfigurations.api-dry-run" dry
      && lib.hasInfix "nixos-rebuild switch" normal
      && lib.hasInfix "nixos-rebuild dry-activate" dry
      && lib.hasInfix "#api-dry-run" dry
    )
    "dry-run app for api-dry-run must still deploy nixosConfigurations.api-dry-run, not api";
}
