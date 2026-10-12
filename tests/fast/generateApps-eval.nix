# Evaluation-time checks for generateApps machine filtering and app keys.
{ pkgs, lib, self, helpers }:
let
  inherit (helpers) assertCheck mkFlake;
  system = pkgs.hostPlatform.system;
  generateApps = self.nixinate.${system};

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

in
{
  eval-filters-non-nixinate-machines = assertCheck "filters-non-nixinate-machines"
    (
      (apps.nixinate ? deployable)
      && !(apps.nixinate ? noNixinateModule)
    )
    "generateApps must only expose machines with _module.args.nixinate set";

  eval-exposes-dry-run-app = assertCheck "exposes-dry-run-app"
    (apps.nixinate ? "deployable-dry-run")
    "expected deployable-dry-run app alongside deployable";

  eval-dry-run-uses-dry-activate = let
    dryRunScript = builtins.readFile apps.nixinate."deployable-dry-run".program;
    normalScript = builtins.readFile apps.nixinate.deployable.program;
  in assertCheck "dry-run-uses-dry-activate"
    (lib.hasInfix "dry-activate" dryRunScript && lib.hasInfix " switch " normalScript)
    "dry-run script should use dry-activate; normal deploy should use switch";

  eval-app-programs-are-store-paths = assertCheck "app-programs-are-store-paths"
    (
      lib.hasPrefix "/nix/store/" apps.nixinate.deployable.program
      && lib.hasPrefix "/nix/store/" apps.nixinate."deployable-dry-run".program
    )
    "deploy app programs should be materialised store paths";
}
