{ inputs, ... }:
{
  inherit inputs;

  rust-overlay = import ./rust-overlay.nix inputs;

  gleam-nix =
    pkgs:
    import ./gleam.nix {
      inherit inputs;
      pkgs = pkgs.extend inputs.self.lib.rust-overlay;
    };

}
