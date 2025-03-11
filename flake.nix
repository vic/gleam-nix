{
  description = "Develop gleam using nix";

  nixConfig = {
    # We no longer ship gleam's Cargo.nix in this repo, since that was causing
    # people to rely on the gleam pinned version.
    # Instead we prefer to generate Cargo.nix from whatever is in gleam's repo.
    # because of this, crate2nix needs this option enabled.
    allow-import-from-derivation = true;

    extra-trusted-public-keys = [
      "gleam-nix.cachix.org-1:JFm9l4KxdKyBNjQFxo/SF5SVjBTGvib/D877Zwf8C0s="
    ];
    extra-substituters = [ "https://gleam-nix.cachix.org" ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    gleam.url = "github:gleam-lang/gleam/v1.0.0";
    gleam.flake = false;

    rust-manifest.url = "https://static.rust-lang.org/dist/channel-rust-1.75.0.toml";
    rust-manifest.flake = false;

    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";

    crate2nix.url = "github:nix-community/crate2nix";
    crate2nix.inputs.nixpkgs.follows = "nixpkgs";

    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";

    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs: inputs.blueprint { inherit inputs; };
}
