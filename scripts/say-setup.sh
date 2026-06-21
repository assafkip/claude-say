#!/usr/bin/env bash
# say-setup.sh - one-time: store your OpenAI API key for /say, securely.
#
# Run this YOURSELF in your terminal (not through Claude). That is deliberate:
# the key never touches the chat transcript. It prompts with the input hidden,
# verifies the key against OpenAI's free GET /v1/models endpoint, then writes it
# to ~/.config/claude-say/openai-key with 600 perms.
#
# Usage:
#   say-setup.sh                # prompt (hidden), verify, save
#   say-setup.sh --no-verify    # save without the network check (offline)
#   printf '%s' "$KEY" | say-setup.sh --no-verify   # non-interactive (tests)
#
# The key is read from stdin, never from a CLI argument, so it can't leak into
# your shell history or a process list.
set -euo pipefail

CONFIG_DIR="${HOME}/.config/claude-say"
KEY_FILE="${CONFIG_DIR}/openai-key"
VERIFY=1
if [[ "${1:-}" == "--no-verify" ]]; then
  VERIFY=0
fi

# Already configured via the environment? The env var wins in say-last-response.py,
# so a key file would be ignored anyway. Nothing to do.
if [[ -n "${OPENAI_API_KEY:-}" ]]; then
  echo "say-setup: \$OPENAI_API_KEY is already set; /say uses that first. Nothing to do."
  exit 0
fi

# A key file already exists -> confirm before overwriting (interactive only).
if [[ -f "$KEY_FILE" && -t 0 ]]; then
  printf "say-setup: a key already exists at %s. Overwrite? [y/N] " "$KEY_FILE"
  read -r reply || true
  [[ "${reply:-}" =~ ^[Yy]$ ]] || { echo "  kept existing key. Nothing changed."; exit 0; }
fi

# Read the key: hidden prompt on a TTY, plain stdin when piped (tests / automation).
# `read` returns non-zero at EOF even when it captured a line with no trailing
# newline, so `|| true` keeps what it read instead of clobbering it.
key=""
if [[ -t 0 ]]; then
  printf "Paste your OpenAI API key (input hidden): "
  read -rs key || true
  echo
else
  read -r key || true
fi

key="$(printf '%s' "$key" | tr -d '[:space:]')"
if [[ -z "$key" ]]; then
  echo "say-setup: no key entered. Nothing written." >&2
  exit 1
fi
case "$key" in
  sk-*) : ;;
  *) echo "say-setup: warning - key does not start with 'sk-'. Saving anyway." >&2 ;;
esac

# Verify against the free models endpoint before trusting it.
if [[ "$VERIFY" -eq 1 ]]; then
  command -v curl >/dev/null 2>&1 || {
    echo "say-setup: curl not found; re-run with --no-verify to skip the check." >&2
    exit 1
  }
  code="$(curl -s -o /dev/null -w '%{http_code}' \
    -H "Authorization: Bearer ${key}" https://api.openai.com/v1/models || echo 000)"
  case "$code" in
    200) echo "say-setup: key verified (OpenAI returned 200)." ;;
    401) echo "say-setup: key rejected (401 unauthorized). Not saved." >&2; exit 1 ;;
    000) echo "say-setup: could not reach OpenAI (offline?). Re-run with --no-verify to save anyway." >&2; exit 1 ;;
    *)   echo "say-setup: unexpected response ($code) from OpenAI. Not saved." >&2; exit 1 ;;
  esac
fi

# Write with tight permissions: 700 dir, 600 file, never echo the key back.
mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR" 2>/dev/null || true
( umask 177; printf '%s' "$key" > "$KEY_FILE" )
chmod 600 "$KEY_FILE"
echo "say-setup: saved to $KEY_FILE (chmod 600). Run /say to use it."
