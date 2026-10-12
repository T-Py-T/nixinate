# Shell script structure shared by all deploy variants.
{ pkgs, lib, self, helpers }:
let
  inherit (helpers) assertCheck mkFlake deployScript;
  system = pkgs.hostPlatform.system;
  generateApps = self.nixinate.${system};

  remoteFlake = mkFlake {
    srv = {
      _module.args.nixinate = {
        host = "srv.example";
        sshUser = "ops";
        buildOn = "remote";
        hermetic = false;
      };
    };
  };

  script = deployScript { inherit generateApps; flake = remoteFlake; machine = "srv"; };
  programPath = (generateApps remoteFlake).nixinate.srv.program;

in
{
  smoke-deploy-script-enables-errexit = assertCheck "deploy-script-enables-errexit"
    (lib.hasInfix "set -e" script)
    "generated deploy scripts should enable errexit";

  smoke-deploy-script-logs-ssh-user-and-host = assertCheck "deploy-script-logs-ssh-user-and-host"
    (
      lib.hasInfix "SSH User: ops" script
      && lib.hasInfix "SSH Host: srv.example" script
    )
    "deploy scripts should echo configured sshUser and host";

  smoke-deploy-program-is-executable-store-path = assertCheck "deploy-program-is-executable-store-path"
    (
      lib.hasPrefix "/nix/store/" programPath
      && lib.hasSuffix "deploy-srv.sh" programPath
    )
    "deploy app program should be a store path ending in deploy-<machine>.sh";
}
