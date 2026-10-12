# Default buildOn = "remote" when only host is configured.
{ pkgs, lib, self, helpers, ... }:
let
  inherit (helpers) assertCheck mkFlake deployScript scriptMustNotMatch;
  system = pkgs.hostPlatform.system;
  generateApps = self.nixinate.${system};

  hostOnlyFlake = mkFlake {
    minimal = {
      _module.args.nixinate = {
        host = "only-host.example";
      };
    };
  };

  script = deployScript {
    inherit generateApps;
    flake = hostOnlyFlake;
    machine = "minimal";
  };

in
{
  behavior-default-buildOn-is-remote = assertCheck "default-buildOn-is-remote"
    (
      lib.hasInfix "Sending flake to minimal via nix copy" script
      && lib.hasInfix "Activating configuration hermetically" script
      && !(lib.hasInfix "Building system closure locally" script)
    )
    "omitting buildOn should default to remote deploy (nix copy + hermetic activation)";

  behavior-default-buildOn-not-local-target-host = scriptMustNotMatch {
    inherit generateApps;
    name = "behavior-default-buildOn-not-local-target-host";
    flake = hostOnlyFlake;
    machine = "minimal";
    patterns = [
      "--target-host"
      "--use-remote-sudo"
    ];
  };
}
