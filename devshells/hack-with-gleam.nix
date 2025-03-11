# for hackin with gleam on your stuff
{
  pkgs,
  inputs,
  perSystem,
  ...
}:
let
  gleamNix = pkgs.callPackage ../gleam.nix { inherit inputs; };
in
perSystem.devshell.mkShell {
  commands = [
    {
      name = "gleam";
      help = pkgs.gleam.meta.description;
      package = gleamNix;
    }
  ];
}
