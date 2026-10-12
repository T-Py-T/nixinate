# Default values for optional nixinate fields (not asserted elsewhere).
{ pkgs, lib, self, helpers }:
let
  inherit (helpers) assertCheck mkFlake deployScript scriptMustNotMatch;
  system = pkgs.hostPlatform.system;
  generateApps = self.nixinate.${system};

  remoteMinimalFlake = mkFlake {
    bare = {
      _module.args.nixinate = {
        host = "bare.remote";
        buildOn = "remote";
      };
    };
  };

  localNoOptsFlake = mkFlake {
    build = {
      _module.args.nixinate = {
        host = "build.local";
        buildOn = "local";
        substituteOnTarget = false;
      };
    };
  };

  bareScript = deployScript {
    inherit generateApps;
    flake = remoteMinimalFlake;
    machine = "bare";
  };

in
{
  smoke-remote-defaults-hermetic-and-root = assertCheck "remote-defaults-hermetic-and-root"
    (
      lib.hasInfix "ssh://root@bare.remote" bareScript
      && lib.hasInfix "Activating configuration hermetically" bareScript
      && lib.hasInfix "nix-store --realise" bareScript
    )
    "remote deploy should default to root sshUser and hermetic activation";

  smoke-local-empty-nixOptions-omits-extra-flags = scriptMustNotMatch {
    inherit generateApps;
    name = "smoke-local-empty-nixOptions-omits-extra-flags";
    flake = localNoOptsFlake;
    machine = "build";
    patterns = [
      "--option connect-timeout"
      "--option "
    ];
  };
}
