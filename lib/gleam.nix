{ inputs, pkgs }:
let
  tools = pkgs.callPackage "${inputs.crate2nix}/tools.nix" { };

  cargoNix =
    (tools.generatedCargoNix {
      name = "gleam";
      src = inputs.gleam;
    }).overrideAttrs
      (prev: {
        buildInputs = [ pkgs.rustc ] ++ prev.buildInputs;
      });

  called = pkgs.callPackage cargoNix { };

  # A derivation for building gleam itself
  gleam = called.workspaceMembers.gleam.build;

  # Packages for people hackin on gleam source.
  gleamDevPackages = {
    inherit (pkgs)
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

    inherit (pkgs)
      erlang
      rebar3
      nodejs
      ;
  };

  # Access to the fenix overlay rust toolchains.
  inherit (pkgs) fenixPackages;

  rustVer =
    with pkgs.lib;
    pipe fenixPackages.manifest.pkg.rust.version [
      (replaceStrings [ "(" ")" ] [ "" "" ])
      (splitString " ")
      (arr: {
        version = elemAt arr 0;
        revision = elemAt arr 1;
        dated = elemAt arr 2;
      })
    ];

  gleamVer = {
    version = gleam.version;
    revision = inputs.gleam.shortRev;
    dated = inputs.gleam.lastModifiedDate;
  };

in
{
  inherit
    gleam
    gleamVer
    rustVer
    cargoNix
    gleamDevPackages
    devPackages
    fenixPackages
    ;
}
