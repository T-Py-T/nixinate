# Mixed local + remote machines in one flake (fleet wiring not covered elsewhere).
{ pkgs, lib, self, helpers }:
let
  inherit (helpers) assertCheck mkFlake deployScript;
  system = pkgs.hostPlatform.system;
  generateApps = self.nixinate.${system};

  fleetFlake = mkFlake {
    laptop = {
      _module.args.nixinate = {
        host = "laptop.corp";
        sshUser = "admin";
        buildOn = "local";
        hermetic = false;
      };
    };
    datacenter = {
      _module.args.nixinate = {
        host = "dc.corp";
        buildOn = "remote";
        hermetic = true;
      };
    };
    legacy = {
      _module.args = { };
    };
  };

  apps = generateApps fleetFlake;
  laptopScript = deployScript { inherit generateApps; flake = fleetFlake; machine = "laptop"; };
  dcScript = deployScript { inherit generateApps; flake = fleetFlake; machine = "datacenter"; };

in
{
  smoke-mixed-fleet-app-keys = assertCheck "mixed-fleet-app-keys"
    (
      lib.length (builtins.attrNames apps.nixinate) == 4
      && (apps.nixinate ? laptop)
      && (apps.nixinate ? datacenter)
      && (apps.nixinate ? "laptop-dry-run")
      && (apps.nixinate ? "datacenter-dry-run")
      && !(apps.nixinate ? legacy)
    )
    "mixed fleet should expose deploy + dry-run only for nixinate-enabled machines";

  smoke-mixed-fleet-script-paths-differ = assertCheck "mixed-fleet-script-paths-differ"
    (
      lib.hasInfix "--target-host admin@laptop.corp" laptopScript
      && lib.hasInfix "Sending flake to datacenter via nix copy" dcScript
      && !(lib.hasInfix "nix copy" laptopScript)
    )
    "local and remote machines in one flake should get distinct deploy strategies";
}
