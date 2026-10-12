# Invalid buildOn must fail when deploy scripts are materialised (abort in mkDeployScript).
{ pkgs, self, repo, ... }:
let
  system = pkgs.hostPlatform.system;

  # builtins.tryEval does not catch abort; use a nested eval in the build sandbox.
  evalReadDeployScript = pkgs.writeText "read-bad-deploy.nix" ''
    let
      flake = builtins.getFlake "${repo}";
      pkgs = import flake.inputs.nixpkgs {
        system = "${system}";
        overlays = [ flake.overlay ];
      };
      generateApps = flake.nixinate.${system};
      badFlake = {
        outPath = "/mock/nixinate-behavior-invalid-flake";
        nixosConfigurations.broken = {
          _module.args.nixinate = {
            host = "broken.example";
            buildOn = "kubernetes";
          };
        };
      };
      program = (generateApps badFlake).nixinate.broken.program;
    in builtins.readFile program
  '';

in
{
  behavior-invalid-buildOn-aborts-on-read = pkgs.runCommand "behavior-invalid-buildOn-aborts-on-read" {
    inherit evalReadDeployScript;
  } ''
    if nix-instantiate --eval --strict ${evalReadDeployScript} >/dev/null 2>&1; then
      echo "invalid buildOn should abort when reading deploy script" >&2
      exit 1
    fi
    touch $out
  '';
}
