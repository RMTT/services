#!/usr/bin/env bash
# Fail every YAML argument that sops reports as not encrypted.
# Used by the git-hooks.nix `sops-encrypted` hook to enforce that all
# YAML under secrets/ (except kustomization.yaml) is sops-encrypted.
set -uo pipefail

status=0
for f in "$@"; do
  if ! out=$(sops filestatus "$f" 2>/dev/null); then
    echo "ERROR: $f could not be parsed by sops" >&2
    status=1
    continue
  fi
  if ! echo "$out" | jq -e '.encrypted == true' >/dev/null 2>&1; then
    echo "ERROR: $f is not sops-encrypted" >&2
    status=1
  fi
done
exit $status
