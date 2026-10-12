#!/usr/bin/env bash
# Fail when root flake.lock inputs are older than MAX_AGE_DAYS (default 90).
set -euo pipefail

ROOT="${1:-.}"
LOCK="${ROOT}/flake.lock"
MAX_AGE_DAYS="${MAX_AGE_DAYS:-90}"

if [[ ! -f "$LOCK" ]]; then
  echo "error: missing $LOCK" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required" >&2
  exit 1
fi

now_epoch="$(date -u +%s)"
max_age_secs=$((MAX_AGE_DAYS * 24 * 60 * 60))
stale=0

while IFS= read -r node; do
  last_modified="$(jq -r ".nodes[\"$node\"].locked.lastModified // empty" "$LOCK")"
  if [[ -z "$last_modified" || "$last_modified" == "null" ]]; then
    continue
  fi
  age_secs=$((now_epoch - last_modified))
  age_days=$((age_secs / 86400))
  rev="$(jq -r ".nodes[\"$node\"].locked.rev // \"unknown\"" "$LOCK")"
  if (( age_secs > max_age_secs )); then
    echo "::warning title=Stale flake input::$node locked at $rev is ${age_days} days old (limit ${MAX_AGE_DAYS})"
    stale=1
  else
    echo "ok: $node ($rev) age ${age_days}d"
  fi
done < <(jq -r '.nodes | keys[]' "$LOCK" | grep -v '^root$' || true)

if (( stale != 0 )); then
  echo "flake.lock has inputs older than ${MAX_AGE_DAYS} days; run nix flake update" >&2
  exit 1
fi

echo "flake.lock inputs are within ${MAX_AGE_DAYS} days"
