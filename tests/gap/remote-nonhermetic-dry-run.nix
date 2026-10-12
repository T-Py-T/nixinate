# Remote non-hermetic deploy and dry-run script details (not covered by tests/fast).
{ pkgs, lib, self, helpers }:
let
  inherit (helpers) assertCheck mkFlake dryRunScript deployScript;
  system = pkgs.hostPlatform.system;
  generateApps = self.nixinate.${system};

  remoteNonHermeticFlake = mkFlake {
    worker = {
      _module.args.nixinate = {
        host = "worker.example.org";
        buildOn = "remote";
        hermetic = false;
        sshUser = "deploy";
      };
    };
  };

  normal = deployScript {
    inherit generateApps;
    flake = remoteNonHermeticFlake;
    machine = "worker";
  };
  dry = dryRunScript {
    inherit generateApps;
    flake = remoteNonHermeticFlake;
    machine = "worker";
  };

in
{
  gap-remote-nonhermetic-flock-path = assertCheck "remote-nonhermetic-flock-path"
    (lib.hasInfix "flock -w 60 /dev/shm/nixinate-worker" normal)
    "non-hermetic remote deploy should flock on a per-machine path under /dev/shm";

  gap-remote-nonhermetic-dry-run-dry-activate = assertCheck "remote-nonhermetic-dry-run-dry-activate"
    (
      lib.hasInfix "nixos-rebuild dry-activate" dry
      && lib.hasInfix "deploy@worker.example.org" dry
    )
    "remote non-hermetic dry-run should SSH with dry-activate, not switch";
}
