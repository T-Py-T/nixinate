# Machines without nixinate args.
{ pkgs, lib, self, helpers }:
let
  inherit (helpers) assertCheck mkFlake;
  system = pkgs.hostPlatform.system;
  generateApps = self.nixinate.${system};

  onlyPlain = mkFlake {
    plain = { _module.args = { }; };
    alsoPlain = { _module.args.other = true; };
  };

  appsEmpty = generateApps onlyPlain;

in
{
  gap-no-nixinate-machines-yields-no-apps = assertCheck "no-nixinate-machines-yields-no-apps"
    (builtins.length (builtins.attrNames appsEmpty.nixinate) == 0)
    "generateApps should not create deploy apps when no machine defines _module.args.nixinate";
}
