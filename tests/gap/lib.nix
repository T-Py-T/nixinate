# Shared helpers for gap-coverage checks (standalone from flake.checks).
{ lib, pkgs }:
{
  assertCheck = name: condition: message:
    pkgs.runCommand "gap-${name}" { } ''
      if ${lib.boolToString condition}; then
        touch $out
      else
        echo "${message}" >&2
        exit 1
      fi
    '';

  mkFlake = configs:
    {
      outPath = "/mock/nixinate-gap-test-flake";
      nixosConfigurations = configs;
    };

  deployScript = { generateApps, flake, machine }:
    builtins.readFile (generateApps flake).nixinate.${machine}.program;

  dryRunScript = { generateApps, flake, machine }:
    builtins.readFile (generateApps flake).nixinate."${machine}-dry-run".program;

  scriptMustMatch = { generateApps, name, flake, machine, patterns }:
    let
      scriptPath = (generateApps flake).nixinate.${machine}.program;
      patternFiles = lib.imap1 (
        i: pattern:
          pkgs.writeText "pattern-${toString i}" pattern
      ) patterns;
    in
    pkgs.runCommand name { } ''
      set -e
      ${lib.concatMapStringsSep "\n" (
        patternFile:
          ''if ! grep -Fq -- "$(cat ${patternFile})" ${scriptPath}; then
            echo "deploy script missing expected pattern: $(cat ${patternFile})" >&2
            exit 1
          fi''
      ) patternFiles}
      touch $out
    '';
}
