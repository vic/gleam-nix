# for hackin on this repository
{
  pkgs,
  inputs,
  perSystem,
  ...
}:
let
  gleamNix = pkgs.callPackage ../gleam.nix { inherit inputs; };

  treefmt = {
    name = "treefmt";
    help = pkgs.treefmt.meta.description;
    command = ''
      ${pkgs.lib.getExe inputs.self.formatter.${pkgs.system}} "''${@}"
    '';
  };

  generate-gleam-cargo-nix = {
    name = "generate-gleam-cargo-nix";
    help = "Generate Cargo.nix from gleam sources";
    command = ''
      ln -sfn ${gleamNix.cargoNix} ./result
      ln -sfn ${gleamNix.cargoNix}/default.nix ./Cargo.nix
      echo "Generated files at ./result -> ${gleamNix.cargoNix}"
    '';
  };

in
perSystem.devshell.mkShell {
  imports = [ "${inputs.devshell}/extra/git/hooks.nix" ];

  devshell.motd = ''
    $(${pkgs.lib.getExe pkgs.glow} ${./hack-on-gleam-nix.md})
    $(menu)
  '';

  git.hooks.enable = true;
  git.hooks.pre-commit.text = ''
    treefmt --ci
  '';

  commands = [
    treefmt
    generate-gleam-cargo-nix
  ];

}
