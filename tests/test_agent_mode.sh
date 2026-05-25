#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repo_root/cli-transcribe"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

agent_mode=false
parse_args --agent
[[ "$agent_mode" == true ]] || fail "--agent should enable agent mode"

transcript='Bitte ändere die Login Logik.'
agent_mode=false
default_output="$(format_transcript "$transcript")"
[[ "$default_output" == "$transcript" ]] || fail "default output should stay unchanged"

agent_mode=true
agent_output="$(format_transcript "$transcript")"
[[ "$agent_output" != "$transcript" ]] || fail "agent output should add context"
[[ "$agent_output" == *"$transcript"* ]] || fail "agent output should include the transcript"
