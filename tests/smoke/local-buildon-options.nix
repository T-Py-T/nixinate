# Local buildOn: hermetic flag is ignored; substituteOnTarget only affects local -s.
{ pkgs, lib, self, helpers }:
let
  inherit (helpers) assertCheck mkFlake deployScript scriptMustMatch scriptMustNotMatch;
  system = pkgs.hostPlatform.system;
  generateApps = self.nixinate.${system};

  localHermeticFlake = mkFlake {
    box = {
      _module.args.nixinate = {
        host = "box.local";
        sshUser = "builder";
        buildOn = "local";
        hermetic = true;
        substituteOnTarget = false;
      };
    };
  };

  remoteSubstFlake = mkFlake {
    edge = {
      _module.args.nixinate = {
        host = "edge.remote";
        buildOn = "remote";
        substituteOnTarget = true;
      };
    };
  };

  localScript = deployScript {
    inherit generateApps;
    flake = localHermeticFlake;
    machine = "box";
  };

in
{
  smoke-local-hermetic-ignores-nix-store-realise = assertCheck "local-hermetic-ignores-realise"
    (
      lib.hasInfix "Building system closure locally" localScript
      && !(lib.hasInfix "nix-store --realise" localScript)
      && !(lib.hasInfix "Activating configuration hermetically" localScript)
    )
    "local buildOn should not use remote hermetic activation even when hermetic = true";

  smoke-local-uses-store-flock = scriptMustMatch {
    inherit generateApps;
    name = "smoke-local-uses-store-flock";
    flake = localHermeticFlake;
    machine = "box";
    patterns = [
      "/nix/store"
      "flock -w 60 /dev/shm/nixinate-box"
    ];
  };

  smoke-remote-ignores-substitute-on-target = scriptMustNotMatch {
    inherit generateApps;
    name = "smoke-remote-ignores-substitute-on-target";
    flake = remoteSubstFlake;
    machine = "edge";
    patterns = [
      "--use-remote-sudo -s"
      " -s "
    ];
  };
}
