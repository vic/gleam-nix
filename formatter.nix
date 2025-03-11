{ pkgs, inputs, ... }:
let
  treefmt = inputs.treefmt-nix.lib.evalModule pkgs {
    projectRootFile = "flake.nix";
    programs.nixfmt.enable = true;
    programs.nixfmt.excludes = [ ".direnv" ];
    programs.deadnix.enable = true;
    programs.mdformat.enable = true;
    programs.yamlfmt.enable = true;
  };
in
treefmt.config.build.wrapper
