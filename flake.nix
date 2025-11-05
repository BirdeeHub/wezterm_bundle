{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixToLua.url = "github:BirdeeHub/nixToLua";
    tmux-navigate-src = {
      url = "github:sunaku/tmux-navigate";
      flake = false;
    };
  };
  outputs = { self, nixpkgs, nixToLua, ... }@inputs: let
    forAllSys = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all;
  in {
    packages = forAllSys (system: let
      pkgs = import nixpkgs { inherit system; };
      tmux = pkgs.callPackage ./tmux.nix {
        inherit (inputs) tmux-navigate-src;
      };
    in{
      default = pkgs.callPackage ./wez {
        inherit tmux nixToLua;
        wrapZSH = true;
        wezterm = pkgs.wezterm;
      };
      wezterm = self.packages.${system}.default.override {
        wrapZSH = false;
        autotx = false;
      };
      inherit tmux;
    });
  };
}
