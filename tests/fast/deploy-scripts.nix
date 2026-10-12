# Generated deploy shell script content (local / remote / hermetic variants).
{ pkgs, lib, self, helpers }:
let
  inherit (helpers) scriptMustMatch scriptMustNotMatch mkFlake;
  system = pkgs.hostPlatform.system;
  generateApps = self.nixinate.${system};

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

  localNoSubstFlake = mkFlake {
    localMachine = {
      _module.args.nixinate = {
        host = "local.example.com";
        sshUser = "ops";
        buildOn = "local";
        hermetic = false;
        substituteOnTarget = false;
      };
    };
  };

  remoteHermeticFlake = mkFlake {
    remoteMachine = {
      _module.args.nixinate = {
        host = "remote.example.com";
        sshUser = "root";
        buildOn = "remote";
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

in
{
  script-local-deploy-target-host = scriptMustMatch {
    inherit generateApps;
    name = "script-local-deploy-target-host";
    flake = localFlake;
    machine = "localMachine";
    patterns = [
      "Building system closure locally, copying it to remote store and activating it"
      "--target-host ops@local.example.com"
      "--use-remote-sudo"
      "-s"
      "--option connect-timeout 5"
      "nixos-rebuild"
    ];
  };

  script-local-no-substitute-flag = scriptMustNotMatch {
    inherit generateApps;
    name = "script-local-no-substitute-flag";
    flake = localNoSubstFlake;
    machine = "localMachine";
    patterns = [
      "--use-remote-sudo -s"
    ];
  };

  script-remote-hermetic-copy-and-realise = scriptMustMatch {
    inherit generateApps;
    name = "script-remote-hermetic-copy-and-realise";
    flake = remoteHermeticFlake;
    machine = "remoteMachine";
    patterns = [
      "Sending flake to remoteMachine via nix copy"
      "Activating configuration hermetically"
      "nix-store --realise"
      "ssh://root@remote.example.com"
      ("/bin/" + "nix")
    ];
  };

  script-remote-nonhermetic-switch = scriptMustMatch {
    inherit generateApps;
    name = "script-remote-nonhermetic-switch";
    flake = remoteNonHermeticFlake;
    machine = "remoteMachine";
    patterns = [
      "Activating configuration non-hermetically"
      "nixos-rebuild switch"
      "remote-nh.example.com"
    ];
  };

  script-local-skips-remote-copy = scriptMustNotMatch {
    inherit generateApps;
    name = "script-local-skips-remote-copy";
    flake = localFlake;
    machine = "localMachine";
    patterns = [
      "Sending flake to localMachine via nix copy"
    ];
  };
}
