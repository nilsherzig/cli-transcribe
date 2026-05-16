{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShell {
  packages = with pkgs; [
    bash
    ffmpeg
    fzf
    pulseaudio
    whisper-cpp-vulkan
    wl-clipboard
  ];
}
