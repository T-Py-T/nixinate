# nixOptions must reach the remote hermetic nixos-rebuild invocation, not only flake copy.
{ pkgs, lib, self, helpers, ... }:
let
  inherit (helpers) assertCheck mkFlake deployScript;
  system = pkgs.hostPlatform.system;
  generateApps = self.nixinate.${system};

  flake = mkFlake {
    cache = {
      _module.args.nixinate = {
        host = "cache.node";
        buildOn = "remote";
        nixOptions = [ "--option" "substitute" "false" ];
      };
    };
  };

  script = deployScript { inherit generateApps; flake = flake; machine = "cache"; };

in
{
  behavior-nixoptions-on-hermetic-ssh-rebuild = assertCheck "nixoptions-on-hermetic-ssh-rebuild"
    (
      let
        afterSsh = lib.elemAt (lib.splitString "ssh://" script) 1;
      in
      lib.hasInfix "--option substitute false" script
      && lib.hasInfix "nixos-rebuild" afterSsh
      && lib.hasInfix "--option substitute false" afterSsh
    )
    "remote hermetic deploy should pass nixOptions to nixos-rebuild inside the SSH command";

  behavior-nixoptions-on-flake-copy-too = assertCheck "nixoptions-on-flake-copy-too"
    (lib.hasInfix "copy /mock/nixinate-behavior-test-flake" script
      && lib.hasInfix "--option substitute false" script)
    "remote deploy should still pass nixOptions to the initial flake nix copy";
}
