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

    gleam.url = "github:gleam-lang/gleam";
    gleam.flake = false;

    rust-manifest.url = "file+https://static.rust-lang.org/dist/channel-rust-1.91.1.toml";
    rust-manifest.flake = false;

    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";

    crate2nix.url = "github:nix-community/crate2nix";
    crate2nix.inputs.nixpkgs.follows = "nixpkgs";
    crate2nix.inputs.devshell.follows = "devshell";
    crate2nix.inputs.pre-commit-hooks.follows = "pre-commit-hooks";
    # Disable dev dependencies
    crate2nix.inputs.crate2nix_stable.follows = "";
    crate2nix.inputs.cachix.follows = "";
    crate2nix.inputs.nix-test-runner.follows = "";

    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";

    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit-hooks.inputs.gitignore.follows = "";
    pre-commit-hooks.inputs.flake-compat.follows = "";
  };

  outputs = inputs: inputs.blueprint { inherit inputs; };
}
