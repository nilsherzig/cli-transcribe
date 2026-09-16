#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repo_root/cli-transcribe"

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
