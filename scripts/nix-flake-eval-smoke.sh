#!/usr/bin/env bash
# Lightweight evaluation smoke test without building VM checks.
set -euo pipefail

cd "${1:-.}"

echo "flake metadata:"
nix flake metadata --json | jq '{description, lastModified, locks}'

echo "evaluating Linux checks (no build):"
nix eval .#checks.x86_64-linux --apply 'builtins.attrNames' --json
