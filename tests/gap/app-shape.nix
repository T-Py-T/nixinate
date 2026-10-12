# Structural checks on generated flake apps.
{ pkgs, lib, self, helpers }:
let
  inherit (helpers) assertCheck mkFlake;
  system = pkgs.hostPlatform.system;
  generateApps = self.nixinate.${system};

  flake = mkFlake {
    srv = {
      _module.args.nixinate = {
        host = "srv.example";
        buildOn = "remote";
        hermetic = false;
      };
    };
  };

  apps = generateApps flake;
  allApps = builtins.attrValues apps.nixinate;

in
{
  gap-generateApps-top-level-is-nixinate-only = assertCheck "generateApps-top-level-is-nixinate-only"
    (builtins.attrNames apps == [ "nixinate" ])
    "generateApps should return only the nixinate app namespace";

  gap-every-deploy-app-is-type-app = assertCheck "every-deploy-app-is-type-app"
    (lib.all (a: a.type == "app") allApps)
    "every generated entry under apps.nixinate must have type = app";

  gap-nixinate-system-attribute-is-function = assertCheck "nixinate-system-attribute-is-function"
    (builtins.isAttrs self.nixinate && builtins.isFunction self.nixinate.${system})
    "flake output nixinate.<system> should be generateApps for each supported system";
}
