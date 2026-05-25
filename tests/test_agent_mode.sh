#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repo_root/cli-transcribe"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

explain_prefix=false
parse_args --explain-prefix
[[ "$explain_prefix" == true ]] || fail "--explain-prefix should enable explain prefix mode"

transcript='Bitte ändere die Login Logik.'
explain_prefix=false
default_output="$(format_transcript "$transcript")"
[[ "$default_output" == "$transcript" ]] || fail "default output should stay unchanged"

explain_prefix=true
agent_output="$(format_transcript "$transcript")"
[[ "$agent_output" != "$transcript" ]] || fail "explain prefix output should add context"
[[ "$agent_output" == *"$transcript"* ]] || fail "explain prefix output should include the transcript"
