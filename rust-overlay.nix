inputs: final: _prev:
let
  ff = inputs.fenix.packages.${final.system}.fromManifestFile inputs.rust-manifest;

  # nixpkgs @all-packages.nix expects rustc.unwrapped.configureFlags to have an "--target=" element.
  # fix that by adding only if configureFlags is empty.
  rustc =
    if final.lib.length ff.rustc.unwrapped.configureFlags > 0 then
      ff.rustc
    else
      ff.rustc
      // {
        unwrapped = ff.rustc.unwrapped // {
          configureFlags = [ "--target=${final.hostPlatform.rust.rustcTarget}" ];
        };
      };

  pkgs = {
    fenixPackages = ff;
    inherit rustc;
    inherit (ff)
      rust
      cargo
      clippy
      lvvm-bitcode-linker
      llvm-tools
      rls
      rust-analysis
      rust-analyzer
      rust-docs
      rust-src
      rust-std
      rustc-dev
      rustc-docs
      rustfmt
      ;
  };
in
pkgs
