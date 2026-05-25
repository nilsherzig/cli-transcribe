#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repo_root/cli-transcribe"

pass() {
  printf 'PASS: %s\n' "$*" >&2
}

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

# --- parse_args tests ---

# --input-file ohne Wert → Fehler (subshell, da die → exit 1)
input_file=""
if ( parse_args --input-file ) 2>/dev/null; then
  fail "--input-file ohne Wert sollte fehlschlagen"
fi
pass "--input-file ohne Wert schlägt fehl"

# --input-file mit Wert setzt input_file
input_file=""
parse_args --input-file /tmp/test.mp4
[[ "$input_file" == "/tmp/test.mp4" ]] || fail "--input-file setzt input_file nicht korrekt"
pass "--input-file mit Wert setzt input_file"

# --input-file und --mic sind inkompatibel
input_file=""
mic=""
if ( parse_args --input-file /tmp/test.mp4 --mic rode ) 2>/dev/null; then
  fail "--input-file und --mic sollten inkompatibel sein"
fi
pass "--input-file und --mic sind inkompatibel (error)"

# --mic und --input-file sind inkompatibel (andere Reihenfolge)
input_file=""
mic=""
if ( parse_args --mic rode --input-file /tmp/test.mp4 ) 2>/dev/null; then
  fail "--mic und --input-file sollten inkompatibel sein (andere Reihenfolge)"
fi
pass "--mic und --input-file sind inkompatibel (error)"

# --- process_input_file tests (using temp dir) ---

work_dir="$(mktemp -d -t cli-transcribe-test.XXXXXX)"
trap 'rm -rf "$work_dir"' EXIT

# Erstelle eine kurze Test-Audio-Datei (2 Sekunden Stille, 48kHz Stereo flac)
# flac wird verwendet, damit ffmpeg wirklich konvertieren muss.
test_input="$work_dir/input.flac"
ffmpeg -y -f lavfi -i anullsrc=r=48000:cl=stereo -t 2 -c:a flac "$test_input" 2>/dev/null
[[ -f "$test_input" ]] || fail "Test-Input-Datei konnte nicht erstellt werden"

audio_file="$work_dir/audio.wav"
process_input_file "$test_input" "$audio_file"

# Ergebnis muss existieren und nicht leer sein
[[ -f "$audio_file" ]] || fail "process_input_file hat audio_file nicht erstellt: $audio_file"
[[ -s "$audio_file" ]] || fail "process_input_file: audio_file ist leer"

# Prüfe Format: mono 16kHz 16-bit PCM WAV
channels=$(ffprobe -v error -select_streams a:0 -show_entries stream=channels -of csv=p=0 "$audio_file")
sample_rate=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of csv=p=0 "$audio_file")
codec=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$audio_file")

[[ "$channels" -eq 1 ]] || fail "Erwartet 1 Kanal (mono), aber ist: $channels"
[[ "$sample_rate" -eq 16000 ]] || fail "Erwartet 16kHz, aber ist: $sample_rate"
[[ "$codec" == "pcm_s16le" ]] || fail "Erwartet pcm_s16le, aber ist: $codec"

pass "process_input_file konvertiert korrekt nach mono 16kHz PCM WAV"

# --- Nicht existierende Datei → Fehler ---
if ( process_input_file "$work_dir/nonexistent.mp4" "$audio_file" ) 2>/dev/null; then
  fail "Nicht existierende Datei sollte fehlschlagen"
fi
pass "Nicht existierende Datei schlägt fehl"

printf '\nAlle Tests bestanden.\n'
