{
  inputs.gleam-nix.url = "path:./..";

  # You can override the repository or revision to use.
  #inputs.gleam-nix.inputs.gleam.url = "github:gleam-lang/gleam?ref=main"

  outputs = {gleam-nix, ...}: let
    inherit (gleam-nix.inputs) flake-utils nixpkgs;
  in
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [gleam-nix.overlays.default];
        };
      in {packages.default = pkgs.gleam;}
    );
}
