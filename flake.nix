{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixToLua.url = "github:BirdeeHub/nixToLua";
    wezterm.url = "github:wez/wezterm?dir=nix";
  };
  outputs = { self, nixpkgs, nixToLua, ... }@inputs: let
    forAllSys = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all;
  in {
    packages = forAllSys (system: let
      pkgs = import nixpkgs { inherit system; };
      tmux = pkgs.callPackage ./tmux {};
    in{
      default = pkgs.callPackage ./wez {
        inherit tmux nixToLua;
        wrapZSH = true;
        wezterm = inputs.wezterm.packages.${system}.default.overrideAttrs {
          # preFixup = '''';
          # postFixup = ''
          #   patchelf \
          #     --add-rpath "${pkgs.libGL}/lib/libEGL.so.1:${pkgs.vulkan-loader}/lib/libvulkan.so.1" \
          #     $out/bin/wezterm-gui
          # '';
        };
      };
      wezterm = self.packages.${system}.default;
      inherit tmux;
    });
  };
}
