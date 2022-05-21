{
  inputs = {
    gleam.url = "github:gleam-lang/gleam";
    gleam.flake = false;

    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;

    nixpkgs.url = "github:nixos/nixpkgs?ref=22.05-pre";
     
    cargo2nix.url = "github:cargo2nix/cargo2nix";
    cargo2nix.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    rust-overlay.inputs.flake-utils.follows = "flake-utils";
  };

  outputs = { self, gleam, nixpkgs, cargo2nix, flake-utils, rust-overlay, ... }:

    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (import "${cargo2nix}/overlay")
            rust-overlay.overlay
          ];
        };

        rustPkgs = pkgs.rustBuilder.makePackageSet' {
          rustChannel = "1.59.0";
          packageFun = import ./Cargo.nix;
          workspaceSrc = gleam;
        };

        workspaceShell = rustPkgs.workspaceShell {
          nativeBuildInputs = with pkgs; [ rust-analyzer ];
        };

	gleamBin = (rustPkgs.workspace.gleam {}).bin;

        packages = {
          gleam = gleamBin;
          default = gleamBin;
        };

        devShells.default = workspaceShell;

	apps = {
	  default = flake-utils.lib.mkApp { drv = gleamBin; };
	  genCargoNix = flake-utils.lib.mkApp { 
	    drv = with pkgs; writeScriptBin "genCargoNix.bash" ''
	    set -xeo pipefail
	    GLEAM_SRC="''${GLEAM_SRC:-$PWD/../gleam}" 
	    GLEAM_NIX="''${GLEAM_NIX:-$PWD}"
	    ${cargo2nix.defaultPackage.${system}}/bin/cargo2nix -f ''${GLEAM_NIX}/Cargo.nix
	    '';
	  };
	};

	checks = {
	  gleamHello = with pkgs; stdenvNoCC.mkDerivation {
	    name = "gleam-hello";
            phases = ["test"];
	    test = ''
	    ${gleamBin}/bin/gleam --help > $out
	    '';
	  };
	};

      in { inherit packages devShells apps checks; }
    );
}
