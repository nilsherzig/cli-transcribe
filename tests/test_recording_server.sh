#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repo_root/cli-transcribe"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

TEST_DIR="$(mktemp -d -t cli-transcribe-server-test.XXXXXX)"
export TEST_DIR
trap 'rm -rf "$TEST_DIR"' EXIT
mkdir -p "$TEST_DIR/bin" "$TEST_DIR/models"
MODEL_DIR="$TEST_DIR/models"
: > "$MODEL_DIR/$MODEL_FILE"
is_macos() { return 0; }

cat > "$TEST_DIR/bin/ffmpeg" <<'EOF'
#!/usr/bin/env bash
printf x > "${@: -1}"
touch "$TEST_DIR/recording.started"
trap 'touch "$TEST_DIR/recording.stopped"; exit 0' TERM
while :; do sleep 0.1; done
EOF
cat > "$TEST_DIR/bin/whisper-server" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$BASHPID" > "$TEST_DIR/server.pid"
touch "$TEST_DIR/server.started"
trap 'exit 0' TERM
while :; do sleep 0.1; done
EOF
cat > "$TEST_DIR/bin/curl" <<'EOF'
#!/usr/bin/env bash
url="${@: -1}"
case "$url" in
  */health) [[ -f "$TEST_DIR/recording.stopped" ]] ;;
  */inference) printf 'mock transcript' ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$TEST_DIR/bin/"*
export PATH="$TEST_DIR/bin:$PATH"

# Do not send the stop signal until both background processes have started.
stop_when_ready() {
  local i
  for ((i=0; i<100; i++)); do
    if [[ -f "$TEST_DIR/server.started" && -f "$TEST_DIR/recording.started" ]]; then
      printf '\n'
      return 0
    fi
    sleep 0.05
  done
  fail 'Recording and server did not start together'
}

result="$(stop_when_ready | main --mic ':0' --stop-on-stdin)"
[[ "$result" == 'mock transcript' ]] || fail "Unexpected transcript: $result"
[[ -f "$TEST_DIR/recording.stopped" ]] || fail 'Recording was not stopped'
server_pid="$(<"$TEST_DIR/server.pid")"
! kill -0 "$server_pid" 2>/dev/null || fail 'Server survived transcription'

# The EXIT trap must also stop a server when recording is aborted.
rm -f "$TEST_DIR/server.started" "$TEST_DIR/server.pid"
(
  start_recording_server "$TEST_DIR"
  trap stop_recording_server EXIT
  for ((i=0; i<100; i++)); do
    [[ -f "$TEST_DIR/server.started" ]] && break
    sleep 0.05
  done
  [[ -f "$TEST_DIR/server.started" ]] || fail 'Server did not start'
  exit 130
) && fail 'Simulated abort should exit non-zero'
server_pid="$(<"$TEST_DIR/server.pid")"
! kill -0 "$server_pid" 2>/dev/null || fail 'Server survived abort'

printf 'PASS: microphone and model start in parallel; server stops on completion and abort\n' >&2
