{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShell {
  packages = with pkgs; [
    bash
    curl
    ffmpeg
    fzf
  ] ++ (if stdenv.hostPlatform.isDarwin then [
    whisper-cpp
  ] else [
    pulseaudio
    whisper-cpp-vulkan
    wl-clipboard
  ]);
}
