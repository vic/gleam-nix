{ pkgs, inputs, ... }: pkgs.callPackage ../gleam.nix { inherit inputs; }
