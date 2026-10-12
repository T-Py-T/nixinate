# Remote SSH wiring and bash tracing flags shared by deploy variants.
{ pkgs, lib, self, helpers, ... }:
let
  inherit (helpers) assertCheck mkFlake deployScript scriptMustMatch;
  system = pkgs.hostPlatform.system;
  generateApps = self.nixinate.${system};

  remoteHermeticFlake = mkFlake {
    hm = {
      _module.args.nixinate = {
        host = "hm.example";
        buildOn = "remote";
      };
    };
  };

  remoteNonHermeticFlake = mkFlake {
    nh = {
      _module.args.nixinate = {
        host = "nh.example";
        buildOn = "remote";
        hermetic = false;
      };
    };
  };

  hermeticScript = deployScript {
    inherit generateApps;
    flake = remoteHermeticFlake;
    machine = "hm";
  };

  nonHermeticScript = deployScript {
    inherit generateApps;
    flake = remoteNonHermeticFlake;
    machine = "nh";
  };

in
{
  behavior-remote-hermetic-uses-nix-sshopts = assertCheck "remote-hermetic-uses-nix-sshopts"
    (lib.hasInfix "\$NIX_SSHOPTS" hermeticScript && lib.hasInfix "openssh" hermeticScript)
    "remote hermetic activation should invoke openssh with NIX_SSHOPTS";

  behavior-remote-nonhermetic-uses-nix-sshopts = assertCheck "remote-nonhermetic-uses-nix-sshopts"
    (lib.hasInfix "\$NIX_SSHOPTS" nonHermeticScript)
    "remote non-hermetic activation should preserve NIX_SSHOPTS for openssh";

  behavior-deploy-scripts-use-set-x = scriptMustMatch {
    inherit generateApps;
    name = "behavior-deploy-scripts-use-set-x";
    flake = remoteHermeticFlake;
    machine = "hm";
    patterns = [ "( set -x;" ];
  };
}
