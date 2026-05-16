> [!WARNING]  
> AI Slop
> also there is `whisper-stream` which can do live transcripts, but its kinda broken for me. But might be worth looking into.

# cli-transcribe

`cli-transcribe` records audio from a PulseAudio microphone with `ffmpeg`, transcribes it with `whisper-cli`, and prints the transcript.

The default Whisper language is German (`de`). The default model is `large-v3-turbo-q8_0`.

## Requirements

Runtime dependencies are provided by the Nix flake:

- `ffmpeg`
- `fzf`
- `pulseaudio` / `pactl`
- `whisper-cpp-vulkan`
- `wl-clipboard` for `--copy`

The model is stored under:

```sh
$HOME/.local/share/cli-transcribe/ggml-large-v3-turbo-q8_0.bin
```

If the model is missing, `cli-transcribe` downloads it automatically with:

```sh
whisper-cpp-download-ggml-model large-v3-turbo-q8_0
```

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

Record with a specific microphone:

```sh
nix run . -- --mic alsa_input.usb-R__DE_Microphones_R__DE_NT-USB_Mini_88C39CC9-00.mono-fallback
```

You can also use a case-insensitive substring:

```sh
nix run . -- --mic rode
```

This matches as if `*rode*` was used. If multiple microphones match, the program exits with an explanation and prints the matching devices.

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
4. Press `Enter` / `Return` to stop recording.
5. Press `Ctrl-C` to abort.
6. The transcript is printed to `stdout`.
7. With `--copy`, the transcript is also copied via `wl-copy`.

Audio and transcript files are stored in a temporary folder like:

```sh
/tmp/cli-transcribe.XXXXXX
```

## CLI reference

```text
cli-transcribe [OPTIONS]

Options:
  --mic <pulse-source>  Microphone/PulseAudio source or substring.
  --lang <lang>         Whisper language. Default: de.
  --copy                Copy transcript to clipboard with wl-copy.
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
