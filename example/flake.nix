{
  inputs.gleam-nix.url = "path:./..";
  outputs = { gleam-nix, ... }: 
  let
    inherit (gleam-nix.inputs) flake-utils nixpkgs;
  in
  flake-utils.lib.eachDefaultSystem (system: 
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ gleam-nix.overlays.default ]; 
      };
    in
    { packages.default = pkgs.gleam; }
  );
}
