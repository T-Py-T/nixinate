# Remote deploy defaults: sshUser, hermetic, flock paths, and nix copy wiring.
{ pkgs, lib, self, helpers }:
let
  inherit (helpers) assertCheck mkFlake deployScript dryRunScript scriptMustMatch;
  system = pkgs.hostPlatform.system;
  generateApps = self.nixinate.${system};

  remoteDefaultsFlake = mkFlake {
    edge = {
      _module.args.nixinate = {
        host = "edge.example.net";
        buildOn = "remote";
        nixOptions = [ "--option" "connect-timeout" "9" ];
      };
    };
  };

  edgeScript = deployScript { inherit generateApps; flake = remoteDefaultsFlake; machine = "edge"; };
  edgeDry = dryRunScript { inherit generateApps; flake = remoteDefaultsFlake; machine = "edge"; };

in
{
  gap-remote-default-ssh-user-is-root = assertCheck "remote-default-ssh-user-is-root"
    (lib.hasInfix "ssh://root@edge.example.net" edgeScript)
    "remote deploy should default sshUser to root when unset";

  gap-remote-default-hermetic-realise = scriptMustMatch {
    inherit generateApps;
    name = "gap-remote-default-hermetic-realise";
    flake = remoteDefaultsFlake;
    machine = "edge";
    patterns = [
      "Activating configuration hermetically"
      "nix-store --realise"
      "/dev/shm/nixinate-edge"
    ];
  };

  gap-remote-nix-options-on-flake-copy = assertCheck "remote-nix-options-on-flake-copy"
    (
      lib.hasInfix "--option connect-timeout 9" edgeScript
      && lib.hasInfix "copy /mock/nixinate-gap-test-flake" edgeScript
    )
    "remote deploy should pass nixOptions to nix copy for the flake";

  gap-remote-dry-run-uses-dry-activate-hermetically = assertCheck "remote-dry-run-dry-activate"
    (
      lib.hasInfix "dry-activate" edgeDry
      && lib.hasInfix "nix-store --realise" edgeDry
      && !(lib.hasInfix " nixos-rebuild switch " edgeDry)
    )
    "remote dry-run should activate with dry-activate, not switch";
}
