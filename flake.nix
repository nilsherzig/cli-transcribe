{
  description = "CLI audio recorder and German-first whisper.cpp transcription tool";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.writeShellApplication {
            name = "cli-transcribe";
            runtimeInputs = with pkgs; [
              bash
              coreutils
              ffmpeg
              fzf
              gawk
              gnugrep
              pulseaudio
              whisper-cpp-vulkan
              wl-clipboard
            ];
            text = builtins.readFile ./cli-transcribe;
          };
        });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/cli-transcribe";
        };
      });

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              bash
              ffmpeg
              fzf
              pulseaudio
              whisper-cpp-vulkan
              wl-clipboard
            ];
          };
        });
    };
}
