{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixToLua.url = "github:BirdeeHub/nixToLua";
    tmux-navigate-src = {
      url = "github:sunaku/tmux-navigate";
      flake = false;
    };
    wrappers = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, nixToLua, ... }@inputs: let
    forAllSys = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all;
  in {
    modules.tmux = import ./tmux.nix inputs;
    wrapperModules.tmux = (inputs.wrappers.lib.evalModule self.modules.tmux).config;
    packages = forAllSys (system: let
      pkgs = import nixpkgs { inherit system; };
      tmux = self.wrapperModules.tmux.wrap { inherit pkgs;};
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
