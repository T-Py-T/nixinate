# Multiple machines and local-build SSH options.
{ pkgs, lib, self, helpers }:
let
  inherit (helpers) assertCheck mkFlake deployScript;
  system = pkgs.hostPlatform.system;
  generateApps = self.nixinate.${system};

  twoMachineFlake = mkFlake {
    alpha = {
      _module.args.nixinate = {
        host = "alpha.internal";
        sshUser = "alpha-user";
        buildOn = "local";
        hermetic = false;
      };
    };
    beta = {
      _module.args.nixinate = {
        host = "beta.internal";
        sshUser = "beta-user";
        buildOn = "local";
        hermetic = false;
      };
    };
  };

  apps = generateApps twoMachineFlake;
  alphaScript = deployScript { inherit generateApps; flake = twoMachineFlake; machine = "alpha"; };
  betaScript = deployScript { inherit generateApps; flake = twoMachineFlake; machine = "beta"; };

in
{
  gap-two-machines-both-get-apps = assertCheck "two-machines-both-get-apps"
    (
      (apps.nixinate ? alpha)
      && (apps.nixinate ? beta)
      && (apps.nixinate ? "alpha-dry-run")
      && (apps.nixinate ? "beta-dry-run")
    )
    "each nixinate-enabled machine should get deploy and dry-run apps";

  gap-per-machine-target-host = assertCheck "per-machine-target-host"
    (
      lib.hasInfix "--target-host alpha-user@alpha.internal" alphaScript
      && lib.hasInfix "--target-host beta-user@beta.internal" betaScript
      && !(lib.hasInfix "beta.internal" alphaScript)
    )
    "local deploy scripts should use each machine's sshUser@host";

  gap-local-deploy-sets-nix-sshopts = assertCheck "local-deploy-sets-nix-sshopts"
    (lib.hasInfix "NIX_SSHOPTS=\"-t\"" alphaScript)
    "local buildOn path should export NIX_SSHOPTS=-t for nixos-rebuild";

  gap-deploy-echo-includes-flake-and-machine = assertCheck "deploy-echo-includes-flake-and-machine"
    (
      lib.hasInfix "Deploying nixosConfigurations.alpha from /mock/nixinate-gap-test-flake" alphaScript
      && lib.hasInfix "Deploying nixosConfigurations.beta from /mock/nixinate-gap-test-flake" betaScript
    )
    "deploy scripts should log the flake reference and configuration name";
}
