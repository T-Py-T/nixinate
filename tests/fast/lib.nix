# Shared helpers for fast (non-VM) nixinate checks.
{ lib, pkgs }:
{
  assertCheck = name: condition: message:
    pkgs.runCommand "fast-${name}" { } ''
      if ${lib.boolToString condition}; then
        touch $out
      else
        echo "${message}" >&2
        exit 1
      fi
    '';

  mkFlake = configs:
    {
      outPath = "/mock/nixinate-fast-test-flake";
      nixosConfigurations = configs;
    };

  scriptMustMatch = { generateApps, name, flake, machine, patterns }:
    let
      apps = generateApps flake;
      scriptPath = apps.nixinate.${machine}.program;
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

  scriptMustNotMatch = { generateApps, name, flake, machine, patterns }:
    let
      apps = generateApps flake;
      scriptPath = apps.nixinate.${machine}.program;
      patternFiles = lib.imap1 (
        i: pattern:
          pkgs.writeText "pattern-${toString i}" pattern
      ) patterns;
    in
    pkgs.runCommand name { } ''
      set -e
      ${lib.concatMapStringsSep "\n" (
        patternFile:
          ''if grep -Fq -- "$(cat ${patternFile})" ${scriptPath}; then
            echo "deploy script should not contain: $(cat ${patternFile})" >&2
            exit 1
          fi''
      ) patternFiles}
      touch $out
    '';
}
