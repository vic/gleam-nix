{ inputs, pkgs }:
let
  pkgs' = pkgs.extend (import ./rust-overlay.nix inputs);
  tools = pkgs'.callPackage "${inputs.crate2nix}/tools.nix" { };
  cargoNix =
    (tools.generatedCargoNix {
      name = "gleam";
      src = inputs.gleam;
    }).overrideAttrs
      (prev: {
        buildInputs = [ pkgs'.rustc ] ++ prev.buildInputs;
      });

  called = pkgs'.callPackage cargoNix { };

  # A derivation for building gleam itself
  gleam = called.workspaceMembers.gleam.build;

  # Packages for people hackin on gleam source.
  gleamDevPackages = {
    inherit (pkgs')
      cargo
      rustc
      rustfmt
      rust-analyzer
      rust-std
      rust-src
      ;
  };

  # Packages for people using gleam to build stuff.
  devPackages = {
    inherit gleam;

    inherit (pkgs')
      erlang
      rebar3
      nodejs
      ;
  };

  # Access to the fenix overlay rust toolchains.
  inherit (pkgs') fenixPackages;

  rustVersion =
    with pkgs'.lib;
    pipe fenixPackages.manifest.pkg.rust.version [
      (replaceStrings [ "(" ")" ] [ "" "" ])
      (splitString " ")
      (arr: {
        version = elemAt arr 0;
        rev = elemAt arr 1;
        release = elemAt arr 2;
      })
    ];

  versionInfo = {
    gleam.rev = inputs.gleam.shortRev;
    gleam.version = gleam.version;
    rust = rustVersion;
  };

in
gleam
// {
  inherit
    versionInfo
    cargoNix
    gleamDevPackages
    devPackages
    fenixPackages
    ;
}
