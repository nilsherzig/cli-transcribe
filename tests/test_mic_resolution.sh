#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repo_root/cli-transcribe"

pass() { printf 'PASS: %s\n' "$*" >&2; }
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

# Mock list_mics für die Tests, damit kein PulseAudio nötig ist.
list_mics() {
  printf '%s\n' \
    "alsa_input.pci-0000_0b_00.4.analog-stereo" \
    "alsa_input.usb-RODE_NT-USB.analog-stereo" \
    "alsa_input.usb-Logitech_StreamCam.analog-stereo"
}

# Exakter Treffer wird zurückgegeben.
result="$(resolve_mic_query "alsa_input.pci-0000_0b_00.4.analog-stereo" 2>/dev/null)"
[[ "$result" == "alsa_input.pci-0000_0b_00.4.analog-stereo" ]] \
  || fail "Exakter Treffer sollte unverändert zurückkommen, war: $result"
pass "exakter Treffer wird zurückgegeben"

# Eindeutiger Substring-Treffer wird aufgelöst.
result="$(resolve_mic_query "rode" 2>/dev/null)"
[[ "$result" == "alsa_input.usb-RODE_NT-USB.analog-stereo" ]] \
  || fail "Substring 'rode' sollte auf RODE-Mic auflösen, war: $result"
pass "eindeutiger Substring-Treffer wird aufgelöst"

# Substring-Matching ist case-insensitive.
result="$(resolve_mic_query "RODE" 2>/dev/null)"
[[ "$result" == "alsa_input.usb-RODE_NT-USB.analog-stereo" ]] \
  || fail "Substring-Matching sollte case-insensitive sein, war: $result"
pass "Substring-Matching ist case-insensitive"

# Kein Treffer → Fehler.
if ( resolve_mic_query "no-such-mic" ) >/dev/null 2>&1; then
  fail "Kein Treffer sollte fehlschlagen"
fi
pass "kein Treffer schlägt fehl"

# Mehrdeutiger Substring → Fehler.
if ( resolve_mic_query "alsa_input" ) >/dev/null 2>&1; then
  fail "Mehrdeutiger Substring sollte fehlschlagen"
fi
pass "mehrdeutiger Substring schlägt fehl"

printf '\nAlle Tests bestanden.\n'
