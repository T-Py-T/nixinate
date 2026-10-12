# Fast evaluation checks for generateApps (no VMs).
{ pkgs, lib, self }:
let
  system = pkgs.hostPlatform.system;
  generateApps = self.nixinate.${system};

  mkFlake = configs:
    {
      outPath = "/mock/nixinate-test-flake";
      nixosConfigurations = configs;
    };

  nixinateArgs = {
    host = "deploy.example.com";
    sshUser = "deployer";
    buildOn = "local";
    hermetic = false;
    substituteOnTarget = true;
    nixOptions = [ "--option" "connect-timeout" "5" ];
  };

  mixedFlake = mkFlake {
    deployable = {
      _module.args.nixinate = nixinateArgs;
    };
    noNixinateModule = {
      _module.args = { };
    };
  };

  apps = generateApps mixedFlake;

  assertCheck = name: condition: message:
    pkgs.runCommand "eval-${name}" { } ''
      if ${lib.boolToString condition}; then
        touch $out
      else
        echo "${message}" >&2
        exit 1
      fi
    '';

in
{
  eval-generateApps-filters-machines = assertCheck "generateApps-filters-machines"
    (
      (apps.nixinate ? deployable)
      && !(apps.nixinate ? noNixinateModule)
    )
    "expected only nixinate-enabled machines to get deploy apps";

  eval-generateApps-dry-run-app = assertCheck "generateApps-dry-run-app"
    (apps.nixinate ? "deployable-dry-run")
    "expected a dry-run app for deployable machine";

  eval-generateApps-dry-run-uses-dry-activate = let
    dryRunScript = builtins.readFile apps.nixinate."deployable-dry-run".program;
  in assertCheck "generateApps-dry-run-uses-dry-activate"
    (lib.hasInfix "dry-activate" dryRunScript)
    "dry-run deploy script should use nixos-rebuild dry-activate";
}
