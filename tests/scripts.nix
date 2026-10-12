# Shell-script content checks for generated deploy scripts (no VMs).
{ pkgs, lib, self }:
let
  system = pkgs.hostPlatform.system;
  generateApps = self.nixinate.${system};

  mkFlake = configs:
    {
      outPath = "/mock/nixinate-test-flake";
      nixosConfigurations = configs;
    };

  scriptMustMatch = name: flake: machine: patterns:
    let
      apps = generateApps flake;
      scriptPath = apps.nixinate.${machine}.program;
    in
    pkgs.runCommand name { } ''
      set -e
      ${lib.concatMapStringsSep "\n" (
        pattern:
          ''if ! grep -Fq ${pkgs.writeText "pattern" pattern} ${scriptPath}; then
            echo "deploy script missing expected pattern: ${pattern}" >&2
            exit 1
          fi''
      ) patterns}
      touch $out
    '';

  localFlake = mkFlake {
    localMachine = {
      _module.args.nixinate = {
        host = "local.example.com";
        sshUser = "ops";
        buildOn = "local";
        hermetic = false;
        substituteOnTarget = true;
        nixOptions = [ "--option" "connect-timeout" "5" ];
      };
    };
  };

  remoteHermeticFlake = mkFlake {
    remoteMachine = {
      _module.args.nixinate = {
        host = "remote.example.com";
        sshUser = "root";
        buildOn = "remote";
        hermetic = true;
      };
    };
  };

  remoteNonHermeticFlake = mkFlake {
    remoteMachine = {
      _module.args.nixinate = {
        host = "remote-nh.example.com";
        buildOn = "remote";
        hermetic = false;
      };
    };
  };

  nixinateNix = lib.getExe pkgs.nixinate.nix;

in
{
  script-local-deploy = scriptMustMatch "script-local-deploy" localFlake "localMachine" [
    "Building system closure locally"
    "--target-host ops@local.example.com"
    "--use-remote-sudo"
    "-s"
    "--option connect-timeout 5"
    nixinateNix
  ];

  script-remote-hermetic-deploy = scriptMustMatch "script-remote-hermetic-deploy" remoteHermeticFlake
    "remoteMachine"
    [
      "Sending flake to remoteMachine via nix copy"
      "Activating configuration hermetically"
      "nix-store --realise"
      nixinateNix
    ];

  script-remote-nonhermetic-deploy = scriptMustMatch "script-remote-nonhermetic-deploy"
    remoteNonHermeticFlake
    "remoteMachine"
    [
      "Activating configuration non-hermetically"
      "nixos-rebuild switch"
    ];
}
