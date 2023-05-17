# Reproducible builds for Gleam.

<pre>
 <code>
  # If you already have Nix installed, try Gleam right away by using:
  $ nix shell github:vic/gleam-nix
  $ gleam --version
  gleam <a href="https://github.com/gleam-lang/gleam/commit/9ba0a5f">0.29.0-rc1</a>
 </code>
</pre>

[![Build history](https://buildstats.info/github/chart/vic/gleam-nix?branch=main)](https://github.com/vic/gleam-nix/actions)

##### Requirements

For using this guide you'll need `nix` version [2.8](https://discourse.nixos.org/t/nix-2-8-0-released/18714)
or latter which must have the [`flakes`](https://nixos.wiki/wiki/Flakes) feature enabled.

See [nix quick-install](https://nixos.org/download.html) or the [install-nix tutorial](https://nix.dev/tutorials/install-nix)
for more in depth instructions.


## Installing Gleam locally (~/.nix-profile)

```shell
# This will install Gleam from latest commit on main branch.
nix profile install github:vic/gleam-nix --override-input gleam github:gleam-lang/gleam/main
gleam --help
```

## Installing Gleam on a flake.

Using the overlay provided by this flake you can add Gleam to any
NixOS system or flake-controlled project environment of yours.


```nix
{
   inputs.gleam-nix.url = "github:vic/gleam-nix";

   outputs = { gleam-nix, nixpkgs, ... }:
     let
      system = "aarch64-darwin"; # or anything you use.
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ gleam-nix.overlays.default ];
      };
     in {
       packages.${system}.gleam = pkgs.gleam;
     };
}
```


## Developing Gleam with a Nix environment.

Also, for Gleam developers, using Nix ensures we get the same
development environment in an instant, all you have to do is
checkout the Gleam repo and run:

```shell
nix develop github:vic/gleam-nix --override-input gleam path:$PWD 
# open your editor and hack hack hack..
cargo run # build dependencies are loaded in your shell
```

Gleam maintainers can also use this to try PR experimental features
from other contributors. Just override where the Gleam source
comes from by specifying the repository/branch name.

```shell
# running gleam to try other people branches:
nix shell github:vic/gleam-nix --override-input gleam github:<someone>/gleam/<cool-branch> -c gleam --help
```

## Contributing

Most of the time this flake should be able to build the latest Gleam source.

```
# Test that the main branch or any other commit is buildable.
nix flake run --override-input gleam github:gleam-lang/gleam/main -- --version
```

However, as Gleam development progresses, this flake might get outdated since
dependencies to build Gleam might have changed. Most of the time, this should
be fixed by regenerating the Cargo.nix file as instructed bellow.

If you contribute a PR, be sure to also update the latest Gleam version
known to build at the first section of this document, so that people can
use the git history if the need to find the commit that can build older versions.


[Nix flakes](https://nixos.wiki/wiki/Flakes) are the secret sauce for nix reproducible builds.
Since all build dependencies get hashed, even the source code.
Every external dependency such external repos (e.g. nixpkgs), 
external utilities (e.g. cargo llvm make), and any Cargo.toml
workspace dependency (read from `Cargo.nix`) gets hashed so that
nix only builds what has actually changed.

If you edit the `flake.nix` file, for example to change the rust
toolchain or the nixpkgs revision, run `nix flake udpate` afterwards
to regenerate the lock file.

Also run `nix run '.#fmt'` to keep al nix files formatted before sending a PR.

#### Regenerating `Cargo.nix`

From time to time the `Cargo.nix` file needs to be re-generated
by using [cargo2nix](https://github.com/cargo2nix/cargo2nix)
in order to keep Gleam's cargo deps nix-controlled.

This is needed when Gleam introduces new dependencies or their versions get updated.

```shell
nix run '.#genCargoNix'
```

#### Updating nixpkgs version

By default this package will build using the latest stable nixpkgs release. 
If you need to update to a most recent release, edit the `nixpkgs.url` line on flake.nix.

#### Updating the rust toolchain.

By default this package will build using the latest rust-stable version.
If you need to update it, edit the `rustChannel` version at flake.nix.


