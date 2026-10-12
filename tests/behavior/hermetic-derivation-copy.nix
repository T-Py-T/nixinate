# Remote hermetic path copies tool derivations alongside the flake.
{ pkgs, lib, self, helpers, ... }:
let
  inherit (helpers) scriptMustMatch mkFlake;
  system = pkgs.hostPlatform.system;
  generateApps = self.nixinate.${system};

  flake = mkFlake {
    node = {
      _module.args.nixinate = {
        host = "node.example";
        buildOn = "remote";
        hermetic = true;
      };
    };
  };

in
{
  behavior-hermetic-single-derivation-copy = scriptMustMatch {
    inherit generateApps;
    name = "behavior-hermetic-single-derivation-copy";
    flake = flake;
    machine = "node";
    patterns = [
      "copy --derivation"
      "nixos-rebuild"
      "flock"
      "Activating configuration hermetically"
    ];
  };

  behavior-hermetic-nonhermetic-do-not-copy-derivations = let
    inherit (helpers) scriptMustNotMatch;
    nonHermeticFlake = mkFlake {
      node = {
        _module.args.nixinate = {
          host = "node.example";
          buildOn = "remote";
          hermetic = false;
        };
      };
    };
  in
    scriptMustNotMatch {
      inherit generateApps;
      name = "behavior-nonhermetic-no-derivation-copy";
      flake = nonHermeticFlake;
      machine = "node";
      patterns = [
        "copy --derivation"
        "nix-store --realise"
      ];
    };
}
