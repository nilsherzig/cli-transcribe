#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repo_root/cli-transcribe"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

work_dir="$(mktemp -d -t cli-transcribe-stdin-test.XXXXXX)"
trap 'rm -rf "$work_dir"' EXIT

fake_bin="$work_dir/bin"
mkdir -p "$fake_bin"
cat > "$fake_bin/ffmpeg" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
output="${@: -1}"
printf x > "$output"
trap 'exit 0' INT TERM
while :; do :; done
EOF
chmod +x "$fake_bin/ffmpeg"

stop_on_stdin=true
old_path="$PATH"
export PATH="$fake_bin:$PATH"
{
  sleep 0.2
  printf '\n'
} | record_audio "test-mic" "$work_dir/audio.wav"
export PATH="$old_path"

[[ -s "$work_dir/audio.wav" ]] || {
  printf 'FAIL: --stop-on-stdin hat die Aufnahme nicht gespeichert\n' >&2
  exit 1
}
printf 'PASS: --stop-on-stdin beendet die Aufnahme über stdin\n' >&2

# A capture process that exits immediately must not wait for a stop signal.
cat > "$fake_bin/ffmpeg" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
mkfifo "$work_dir/stop"
{
  sleep 4
  printf '\n'
} > "$work_dir/stop" &
writer_pid=$!
export PATH="$fake_bin:$old_path"
start=$SECONDS
if ( record_audio "invalid-mic" "$work_dir/failed.wav" < "$work_dir/stop" ) 2>/dev/null; then
  kill "$writer_pid" 2>/dev/null || true
  fail "An invalid microphone should fail"
fi
kill "$writer_pid" 2>/dev/null || true
wait "$writer_pid" 2>/dev/null || true
[[ $((SECONDS - start)) -lt 3 ]] || fail "Capture failure should not wait for stdin"
printf 'PASS: fehlgeschlagene Aufnahme wartet nicht auf stdin\n' >&2
