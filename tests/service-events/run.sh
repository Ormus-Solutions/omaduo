#!/usr/bin/env bash
# Loads Service.qml in a throwaway Quickshell instance and runs shell.qml.
# Quickshell only imports types from inside its config folder, so the
# service is copied next to the test. Needs a running Wayland session.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$here/../.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cp "$root/Service.qml" "$here/shell.qml" "$tmp/"
ln -s "$root/bin" "$tmp/bin"
out=$(timeout 30 quickshell -p "$tmp" 2>&1) || true
grep -E 'PASS|FAIL|ERROR' <<<"$out" | head -n 5
grep -q 'PASS service-events' <<<"$out"
