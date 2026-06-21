#!/usr/bin/env bash
# test-say-setup.sh - Prove say-setup.sh stores the key securely WITHOUT a
# network call and WITHOUT touching the real ~/.config/claude-say. Every case
# runs against a throwaway HOME so the real key file is never read or written.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP="$SCRIPT_DIR/../say-setup.sh"
PASS=0
FAIL=0
ok()  { echo "  PASS: $1"; PASS=$((PASS+1)); }
bad() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

# Each run gets a fresh fake HOME and an empty OPENAI_API_KEY so the env-wins
# branch doesn't short-circuit the cases that test file writing.
run() {
  local home="$1"; shift
  HOME="$home" OPENAI_API_KEY="" bash "$SETUP" "$@"
}

echo "test-say-setup: secure key storage, no network"

# 1. Piped key + --no-verify writes the file with exact content and 600 perms.
H1="$(mktemp -d)"; trap 'rm -rf "$H1"' EXIT
printf '%s' "sk-test-ABC123" | run "$H1" --no-verify >/dev/null 2>&1
KF="$H1/.config/claude-say/openai-key"
[ -f "$KF" ]                                  && ok "writes the key file"        || bad "no key file written"
[ "$(cat "$KF" 2>/dev/null)" = "sk-test-ABC123" ] && ok "content matches exactly" || bad "content wrong"
perm="$(stat -f '%Lp' "$KF" 2>/dev/null || stat -c '%a' "$KF" 2>/dev/null)"
[ "$perm" = "600" ]                           && ok "key file is chmod 600"       || bad "perms are $perm (want 600)"

# 2. Empty input -> non-zero exit, nothing written.
H2="$(mktemp -d)"
if printf '' | run "$H2" --no-verify >/dev/null 2>&1; then code=0; else code=$?; fi
[ "$code" -ne 0 ]                             && ok "empty key exits non-zero"    || bad "empty key exit 0"
[ ! -f "$H2/.config/claude-say/openai-key" ]  && ok "empty key wrote nothing"     || bad "empty key wrote a file"
rm -rf "$H2"

# 3. $OPENAI_API_KEY already set -> exits 0, writes no file (env wins).
H3="$(mktemp -d)"
HOME="$H3" OPENAI_API_KEY="sk-env-key" bash "$SETUP" --no-verify >/dev/null 2>&1 && code=0 || code=$?
[ "$code" -eq 0 ]                             && ok "env key set -> exit 0"        || bad "env key exit $code"
[ ! -f "$H3/.config/claude-say/openai-key" ]  && ok "env key set -> no file"       || bad "env key wrote a file"
rm -rf "$H3"

echo "test-say-setup: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
