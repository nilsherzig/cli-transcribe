> [!WARNING]  
> AI Slop

# cli-transcribe

`cli-transcribe` records audio with `ffmpeg` (PulseAudio on Linux, AVFoundation on macOS), transcribes it with `whisper-cli`, and prints the transcript.

It also has a `--live` mode: it records continuously, detects finished speech segments with Silero VAD (`whisper-vad-speech-segments`), and transcribes each segment as you speak. This replaces the upstream `whisper-stream`, which re-transcribes an overlapping sliding window (janky output) and offers no clean final transcript.

The default Whisper language is German (`de`). The default model is `large-v3-turbo-q8_0`.

## Requirements

Runtime dependencies are provided by the Nix flake:

- `ffmpeg`
- `fzf`
- Linux: `pulseaudio` / `pactl`, `whisper-cpp-vulkan`, and `wl-clipboard` for `--copy`
- macOS: `whisper-cpp` (Metal enabled automatically on Apple Silicon); `--copy` uses the system `pbcopy`

The `--stop-on-stdin` option is available for integrations that need to stop a
recording without competing with the terminal's interactive input.

The models are stored under:

```sh
$HOME/.local/share/cli-transcribe/ggml-large-v3-turbo-q8_0.bin   # Whisper
$HOME/.local/share/cli-transcribe/ggml-silero-v5.1.2.bin         # VAD (live mode)
```

If a model is missing, `cli-transcribe` downloads it automatically. The Whisper model comes from `whisper-cpp-download-ggml-model`; the VAD model is fetched with `curl` from `huggingface.co/ggml-org/whisper-vad`. On macOS, allow microphone access for the terminal application running the command when prompted.

## Usage

Run from this repository:

```sh
nix run .
```

List microphones:

```sh
nix run . -- --list-mics
```

Record with interactive microphone selection via `fzf`:

```sh
nix run .
```

Live transcription (prints each finished segment to stderr as you speak, the full transcript to stdout on `Enter`):

```sh
nix run . -- --live
nix run . -- --live --mic rode --copy
```

Tune the VAD with environment variables if segments get dropped or over-split:

```sh
LIVE_MIN_SILENCE_MS=300 nix run . -- --live   # split on shorter pauses
LIVE_VAD_THRESHOLD=0.3   nix run . -- --live   # keep quieter speech
```

Record with a specific microphone:

```sh
nix run . -- --mic alsa_input.usb-R__DE_Microphones_R__DE_NT-USB_Mini_88C39CC9-00.mono-fallback # Linux
nix run . -- --mic ':0' # macOS: AVFoundation audio index from --list-mics
```

You can also use a case-insensitive substring:

```sh
nix run . -- --mic rode
```

This matches as if `*rode*` was used. If multiple microphones match, the program exits with an explanation and prints the matching devices. On macOS, `--list-mics` prints the AVFoundation audio index and name (for example, `:0 MacBook Air Microphone`); either the index (`--mic ':0'`) or a unique part of the name can be used. Passing an index skips device enumeration for faster startup.

Set language:

```sh
nix run . -- --lang de
nix run . -- --lang en
nix run . -- --lang auto
```

Copy transcript to clipboard:

```sh
nix run . -- --copy
```

Format transcript for a coding agent:

```sh
nix run . -- --explain-prefix
nix run . -- --copy --explain-prefix
```

Show verbose `ffmpeg` and `whisper-cli` output:

```sh
nix run . -- -v
```

Show help:

```sh
nix run . -- --help
```

## Recording flow

1. The Whisper model is checked and downloaded if missing.
2. A microphone is selected via `fzf` or resolved from `--mic`.
3. Recording starts.
4. Press `Enter` / `Return` to stop recording (or use `--stop-on-stdin` for a newline-controlled integration).
5. Press `Ctrl-C` to abort.
6. The transcript is printed to `stdout`.
7. With `--explain-prefix`, the printed/copied text includes context for a coding agent.
8. With `--copy`, the transcript is also copied via `wl-copy` (Linux) or `pbcopy` (macOS).

Audio and transcript files are stored in a temporary folder like:

```sh
/tmp/cli-transcribe.XXXXXX
```

## CLI reference

```text
cli-transcribe [OPTIONS]

Options:
  --mic <device>        Microphone source/index or substring.
  --live                Live mode: transcribe finished speech segments as you speak.
  --stop-on-stdin       Stop microphone recording when a line is received on stdin.
  --lang <lang>         Whisper language. Default: de.
  --copy                Copy transcript to clipboard.
  --explain-prefix      Add context around the transcript for coding agents.
  -v, --verbose         Show verbose ffmpeg and whisper-cli output.
  --list-mics           List available microphones.
  -h, --help            Show help.
```

## Development shell

Enter a shell with all dependencies:

```sh
nix develop
```

Then run the script directly:

```sh
./cli-transcribe --help
./cli-transcribe --list-mics
./cli-transcribe --mic rode
```

## Install for the current user

From this repository:

```sh
nix profile install .
```

Then run:

```sh
cli-transcribe
cli-transcribe --help
cli-transcribe --list-mics
```

Uninstall:

```sh
nix profile remove cli-transcribe
```

## Install on NixOS system-wide

If flakes are not enabled yet, add this to your NixOS configuration:

```nix
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
```

### From a local checkout

Example `configuration.nix`:

```nix
{ pkgs, ... }:

let
  cli-transcribe = builtins.getFlake "/home/nils/Documents/projects/cli-transcribe";
in
{
  environment.systemPackages = [
    cli-transcribe.packages.${pkgs.system}.default
  ];
}
```

Apply:

```sh
sudo nixos-rebuild switch
```

### From GitHub

If this repository is available on GitHub, for example as `github:USER/cli-transcribe`:

```nix
{ pkgs, ... }:

let
  cli-transcribe = builtins.getFlake "github:USER/cli-transcribe";
in
{
  environment.systemPackages = [
    cli-transcribe.packages.${pkgs.system}.default
  ];
}
```

Apply:

```sh
sudo nixos-rebuild switch
```

After installation:

```sh
cli-transcribe --help
cli-transcribe --mic rode --copy
```
