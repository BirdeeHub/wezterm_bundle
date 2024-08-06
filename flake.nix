{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };
  outputs = { self, nixpkgs, ... }@inputs: let
    forAllSys = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all;
  in {
    packages = forAllSys (system: let
      pkgs = import nixpkgs { inherit system; };
      tmux = pkgs.callPackage ./tmux { isAlacritty = false; };
      zdotdir = pkgs.callPackage ./zdot {};
    in{
      default = pkgs.callPackage ./wez { inherit tmux zdotdir; wrapZSH = true; };
      wezterm = self.packages.${system}.default;
      inherit tmux;
    });
  };
}
