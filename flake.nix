{
  inputs = {
    gleam.url = "github:gleam-lang/gleam/v1.0.0";
    gleam.flake = false;

    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;

    nixpkgs.url = "github:nixos/nixpkgs?ref=23.11";

    cargo2nix.url = "github:cargo2nix/cargo2nix";
    cargo2nix.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    rust-overlay.inputs.flake-utils.follows = "flake-utils";
  };

  outputs = {
    self,
    gleam,
    nixpkgs,
    cargo2nix,
    flake-utils,
    rust-overlay,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            cargo2nix.overlays.default
            rust-overlay.overlays.default
          ];
        };

        rustPkgs = pkgs.rustBuilder.makePackageSet {
          rustChannel = "1.74.0";
          packageFun = import ./Cargo.nix;
          workspaceSrc = gleam;
        };

        workspaceShell = rustPkgs.workspaceShell {
          nativeBuildInputs = with pkgs; [rust-analyzer];
        };

        gleamBin = (rustPkgs.workspace.gleam {}).bin;

        packages = {
          gleam = gleamBin;
          default = gleamBin;
        };

        devShells.default = workspaceShell;

        apps = {
          default = flake-utils.lib.mkApp {drv = gleamBin;};

          fmt = flake-utils.lib.mkApp {
            drv = with pkgs;
              writeScriptBin "fmt" ''
                #!/bin/bash
                ${pkgs.alejandra}/bin/alejandra "$@" -e ./Cargo.nix .
              '';
          };

          genCargoNix = flake-utils.lib.mkApp {
            drv = with pkgs;
              writeScriptBin "genCargoNix.bash" ''
                #!/bin/bash
                set -xeuo pipefail
                GLEAM_NIX="''${1:-$PWD}"
                GLEAM_SRC="''${2:-${gleam}}"
                ${cargo2nix.packages.${system}.default}/bin/cargo2nix "$GLEAM_SRC" --locked --file $GLEAM_NIX/Cargo.nix
              '';
          };
        };

        checks = {
          gleamHello = with pkgs;
            stdenvNoCC.mkDerivation {
              name = "gleam-hello";
              phases = ["test"];
              test = ''
                ${gleamBin}/bin/gleam --help > $out
              '';
            };
        };
      in {inherit packages devShells apps checks;}
    )
    // {
      overlays.default = final: prev: {inherit (self.packages.${final.system}) gleam;};
    };
}
