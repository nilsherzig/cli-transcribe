#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repo_root/cli-transcribe"

pass() { printf 'PASS: %s\n' "$*" >&2; }
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

# Test: Prozess der sofort beendet wird wird erkannt.
true &
local_pid=$!
wait_for_pid_exit "$local_pid" 5 || fail "Sofort beendeter Prozess sollte erkannt werden"
pass "sofort beendeter Prozess wird erkannt"

# Test: Langanhaltender Prozess mit kleinem Timeout kehrt mit 1 zurück.
sleep 10 &
local_pid=$!
if wait_for_pid_exit "$local_pid" 1; then
  kill "$local_pid" 2>/dev/null || true
  wait "$local_pid" 2>/dev/null || true
  fail "Timeout sollte mit Rückgabewert 1 enden"
fi
kill "$local_pid" 2>/dev/null || true
wait "$local_pid" 2>/dev/null || true
pass "Timeout bei langlaufendem Prozess kehrt mit 1 zurück"

# Test: Mehrere Iterationen bis Prozess endet.
sleep 0.3 &
local_pid=$!
wait_for_pid_exit "$local_pid" 10 || fail "Prozess der innerhalb des Timeouts endet sollte erkannt werden"
pass "Prozess endet innerhalb des Timeouts"

printf '\nAlle Tests bestanden.\n'
