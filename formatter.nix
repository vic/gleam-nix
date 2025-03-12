{ pkgs, inputs, ... }:
let
  treefmt = inputs.treefmt-nix.lib.evalModule pkgs {
    projectRootFile = "flake.nix";
    programs.nixfmt.enable = true;
    programs.nixfmt.excludes = [ ".direnv" ];
    programs.deadnix.enable = true;
    programs.mdformat.enable = true;
    programs.yamlfmt.enable = true;
    programs.shfmt.enable = true;
    programs.shellcheck.enable = true;
    programs.shellcheck.excludes = [
      ".envrc"
      ".direnv"
    ];
  };
in
treefmt.config.build.wrapper
