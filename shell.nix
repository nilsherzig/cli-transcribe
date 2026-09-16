{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShell {
  packages = with pkgs; [
    bash
    curl
    ffmpeg
    fzf
    pulseaudio
    whisper-cpp-vulkan
    wl-clipboard
  ];
}
