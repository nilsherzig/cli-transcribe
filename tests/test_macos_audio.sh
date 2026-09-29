#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repo_root/cli-transcribe"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

work_dir="$(mktemp -d -t cli-transcribe-macos-test.XXXXXX)"
trap 'rm -rf "$work_dir"' EXIT
mkdir -p "$work_dir/bin"
cat > "$work_dir/bin/ffmpeg" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' \
  '[AVFoundation indev @ 0x123] AVFoundation video devices:' \
  '[AVFoundation indev @ 0x123] [0] FaceTime Camera' \
  '[AVFoundation indev @ 0x123] AVFoundation audio devices:' \
  '[AVFoundation indev @ 0x123] [0] MacBook Air Microphone' \
  '[AVFoundation indev @ 0x123] [1] USB Microphone' >&2
exit 1
EOF
chmod +x "$work_dir/bin/ffmpeg"
export PATH="$work_dir/bin:$PATH"

is_macos() { return 0; }
result="$(list_mics)"
[[ "$result" == $':0 MacBook Air Microphone\n:1 USB Microphone' ]] \
  || fail "AVFoundation audio devices should exclude video devices, got: $result"
[[ "$(resolve_mic_query 'usb')" == ':1 USB Microphone' ]] \
  || fail 'Microphone name should resolve to its AVFoundation index'
# A numeric AVFoundation index goes straight to ffmpeg without enumerating devices.
list_mics() { fail 'Explicit AVFoundation index must not list devices'; }
[[ "$(resolve_mic_query ':0')" == ':0' ]] \
  || fail 'AVFoundation index should pass through directly'
set_audio_capture_args ':0'
[[ "${AUDIO_CAPTURE_ARGS[*]}" == '-f avfoundation -i :0' ]] \
  || fail "Unexpected direct macOS capture arguments: ${AUDIO_CAPTURE_ARGS[*]}"
set_audio_capture_args ':1 USB Microphone'
[[ "${AUDIO_CAPTURE_ARGS[*]}" == '-f avfoundation -i :1' ]] \
  || fail "Unexpected macOS capture arguments: ${AUDIO_CAPTURE_ARGS[*]}"

is_macos() { return 1; }
set_audio_capture_args 'alsa_input.test'
[[ "${AUDIO_CAPTURE_ARGS[*]}" == '-f pulse -i alsa_input.test' ]] \
  || fail "Unexpected Linux capture arguments: ${AUDIO_CAPTURE_ARGS[*]}"

printf 'PASS: macOS microphone listing, resolution and capture arguments\n' >&2
