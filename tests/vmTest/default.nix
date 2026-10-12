{
  pkgs,
  inputs,
}:
let
  inherit (pkgs) lib;
  # Return a store path with a closure containing everything including
  # derivations and all build dependency outputs, all the way down.
  closurePaths =
    pkg:
    lib.filter (p: p != "") (
      lib.splitString "\n" (
        builtins.readFile (
          pkgs.writeClosure [
            pkg
          ]
        )
      )
    );
  # Omit the system toplevel itself; registering it in additionalPaths breaks QEMU VM config evaluation.
  closureDeps = pkg: lib.filter (p: p != pkg) (closurePaths pkg);
  # Imports a flake with inputs passed in by hand, rather than
  # builtins.getFlake, which cannot be used in this way.
  callLocklessFlake =
    path: inputs:
    let
      r = {
        outPath = path;
      }
      // ((import (path + "/flake.nix")).outputs (inputs // { self = r; }));
    in
    r;
  mkNixinateTest =
    {
      buildOn,
      hermetic ? false,
      ...
    }:
    let
      exampleFlake = pkgs.writeTextFile {
        name = "nixinate-example-flake";
        destination = "/flake.nix";
        text = ''
          {
            outputs = { self, nixpkgs }:
              let
                system = "${pkgs.hostPlatform.system}";
              in
              {
                nixosConfigurations.nixinatee = nixpkgs.lib.nixosSystem {
                  inherit system;
                  modules = [
                    ${builtins.readFile ./nixinateeBase.nix}
                    ${builtins.readFile ./nixinateeAdditional.nix}
                    {
                      _module.args.nixinate = {
                        host = "nixinatee";
                        sshUser = "nixinator";
                        buildOn = "${buildOn}";
                        hermetic = ${lib.boolToString hermetic};
                      };
                    }
                  ];
                };
              };
          }
        '';
      };
      deployScript = inputs.self.nixinate.${pkgs.hostPlatform.system} (
        callLocklessFlake "${exampleFlake}" { nixpkgs = inputs.nixpkgs; }
      );
      exampleSystem =
        (callLocklessFlake "${exampleFlake}" { nixpkgs = inputs.nixpkgs; })
        .nixosConfigurations.nixinatee.config.system.build.toplevel;
    in
    pkgs.testers.runNixOSTest {
      name = "nixinate-vm-${buildOn}${if hermetic then "-hermetic" else ""}";
      nodes = {
        nixinatee = { ... }: {
          imports = [
            ./nixinateeBase.nix
            (import ./common.nix { inherit inputs; })
          ];
          virtualisation = {
            writableStore = true;
            additionalPaths = lib.concatLists [
              (lib.optionals (buildOn == "remote") [ exampleFlake ])
              (lib.optionals hermetic (closureDeps pkgs.nixinate.nixos-rebuild))
              (lib.optionals hermetic (closureDeps pkgs.flock))
            ];
          };
        };
        nixinator = { ... }: {
          imports = [
            (import ./common.nix { inherit inputs; })
          ];
          virtualisation.additionalPaths = lib.concatLists [
            (lib.optionals (buildOn == "remote") [ exampleFlake ])
            (lib.optionals hermetic (closureDeps pkgs.flock))
          ];
        };
      };
      testScript = ''
        start_all()
        nixinatee.wait_for_unit("sshd.service")
        nixinator.wait_for_unit("multi-user.target")
        nixinator.succeed("mkdir ~/.ssh/")
        nixinator.succeed("ssh-keyscan -H nixinatee >> ~/.ssh/known_hosts")
        nixinator.succeed("exec ${deployScript.nixinate.nixinatee.program} >&2")
        nixinatee.wait_for_unit("nginx.service")
        nixinatee.wait_for_open_port(80)
        with subtest("Check that Nginx webserver can be reached by deployer after deployment"):
            assert "<title>Welcome to nginx!</title>" in nixinator.succeed(
                "curl -sSf http:/nixinatee/ | grep title"
            )
        with subtest("Check that Nginx webserver can be reached by deployee after deployment"):
            assert "<title>Welcome to nginx!</title>" in nixinatee.succeed(
                "curl -sSf http:/127.0.0.1/ | grep title"
            )
      '';
    };
in
{
  local = (mkNixinateTest { buildOn = "local"; });
  remote = (mkNixinateTest { buildOn = "remote"; });
  localHermetic = (
    mkNixinateTest {
      buildOn = "local";
      hermetic = true;
    }
  );
  remoteHermetic = (
    mkNixinateTest {
      buildOn = "remote";
      hermetic = true;
    }
  );
}
