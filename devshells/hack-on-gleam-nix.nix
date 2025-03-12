# for hackin on this repository
{
  pkgs,
  inputs,
  perSystem,
  ...
}:
let
  gleamNix = inputs.self.lib.gleam-nix pkgs;

  treefmt = pkgs.writeShellApplication {
    name = "treefmt";
    meta.description = pkgs.treefmt.meta.description;
    text = ''
      ${pkgs.lib.getExe inputs.self.formatter.${pkgs.system}} "''${@}"
    '';
  };

  generate-gleam-cargo-nix = pkgs.writeShellApplication {
    name = "generate-gleam-cargo-nix";
    meta.description = "Generate Cargo.nix from gleam sources";
    text = ''
      ln -sfn ${gleamNix.cargoNix} ./result
      ln -sfn ${gleamNix.cargoNix}/default.nix ./Cargo.nix
      echo "Generated files at ./result -> ${gleamNix.cargoNix}"
    '';
  };

  show-gleam-version = pkgs.writeShellApplication {
    name = "show-gleam-version";
    meta.description = "Display gleam revision and version";
    text =
      let
        file = pkgs.writeText "gleam.json" (builtins.toJSON gleamNix.gleamVer);
      in
      ''
        ${pkgs.lib.getExe pkgs.jq} -r . ${file}
      '';
  };

  show-rust-version = pkgs.writeShellApplication {
    name = "show-rust-version";
    meta.description = "Display rust revision and version";
    text =
      let
        file = pkgs.writeText "gleam.json" (builtins.toJSON gleamNix.rustVer);
      in
      ''
        ${pkgs.lib.getExe pkgs.jq} -r . ${file}
      '';
  };

  bump-rust-manifest = pkgs.writeShellApplication {
    name = "bump-rust-manifest";
    meta.description = "Bump rust-manifest version on flake.nix";
    runtimeInputs = with pkgs; [ coreutils ];
    text =
      let
        currVersion = gleamNix.rustVer.version;
        nextVersion = gleamNix.rustBumpedVer;
      in
      ''
        sed -i -e "s#channel-rust-${currVersion}.toml#channel-rust-${nextVersion}.toml#" flake.nix
      '';
  };

  gh-flake-update = pkgs.writeShellApplication {
    name = "gh-flake-update";
    meta.description = "Trying to run daily gleam on CI";
    runtimeInputs = with pkgs; [
      jq
      gh
      git
      nix
      coreutils
      show-rust-version
      show-gleam-version
      bump-rust-manifest
    ];
    text = builtins.readFile ./hack-on-gleam-nix/gh-flake-update.bash;
  };

in
perSystem.devshell.mkShell {
  imports = [ "${inputs.devshell}/extra/git/hooks.nix" ];

  devshell.packages = [
    gh-flake-update
    bump-rust-manifest
  ];

  devshell.motd = ''
    $(${pkgs.lib.getExe pkgs.glow} ${./hack-on-gleam-nix.md})
    $(menu)
  '';

  git.hooks.enable = true;
  git.hooks.pre-commit.text = ''
    treefmt --ci
  '';

  commands = [
    { package = treefmt; }
    { package = generate-gleam-cargo-nix; }
    { package = show-gleam-version; }
    { package = show-rust-version; }
  ];

}
