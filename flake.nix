{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    tmux-navigate-src = {
      url = "github:sunaku/tmux-navigate";
      flake = false;
    };
    wrappers = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      # url = "git+file:/home/birdee/Projects/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, ... }@inputs: let
    forAllSys = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all;
  in {
    modules.tmux = import ./tmux.nix inputs;
    modules.wezterm = import ./wez inputs;
    wrapperModules.tmux = (inputs.wrappers.lib.evalModule self.modules.tmux).config;
    wrapperModules.wezterm = (inputs.wrappers.lib.evalModule self.modules.wezterm).config;
    packages = forAllSys (system: let
      pkgs = import nixpkgs { inherit system; };
    in{
      default = self.wrapperModules.wezterm.wrap { inherit pkgs; wrapZSH = true; withLauncher = true; };
      wezterm = self.wrapperModules.wezterm.wrap { inherit pkgs; };
      tmux = self.wrapperModules.tmux.wrap { inherit pkgs; };
    });
  };
}
