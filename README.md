# Reproducible builds for Gleam.

[nix](https://nixos.org/) is a purely functional package manager with
fully-cacheable, to-the-byte reproducible builds. 

This guide documents how people using the Nix package manager or 
NixOS systems can easily build every version of Gleam with just
a single command.

<img width="1027" alt="Screen Shot 2021-12-20 at 18 31 47" src="https://user-images.githubusercontent.com/331/146850903-6fd42dda-cef3-4f3b-a720-1916ba91ca22.png">


##### Requirements

For using this guide you'll need `nix` version [2.8](https://discourse.nixos.org/t/nix-2-8-0-released/18714)
or latter which must have the [`flakes`](https://nixos.wiki/wiki/Flakes) feature enabled.

See [nix quick-install](https://nixos.org/download.html) or the [install-nix tutorial](https://nix.dev/tutorials/install-nix)
for more in depth instructions.

## Running Gleam nightly. (or any branch/commit)

The following command runs `gleam --help` on the build from
the latest commit on `main` branch.

```shell
# The latest commit from Gleam's main branch. (can be a commit hash, tag or branch name)
nix shell github:vic/gleam-nix --override-input gleam github:gleam-lang/gleam/main -c gleam --help
```

Gleam maintainers can also use this to try PR experimental features
from other contributors just by overriding where the Gleam source
comes from specifying the repository/branch name.

```shell
# running gleam to try other people branches:
nix shell github:vic/gleam-nix --override-input gleam github:<someone>/gleam/<cool-feature> -c gleam --help
```

## Developing Gleam with a Nix environment.

Also, for Gleam developers, using Nix ensures we get the same
development environment in an instant, all you have to do is
checkout the Gleam repo and run:

```shell
nix develop github:vic/gleam-nix --override-input gleam path:$PWD # -c fish # you might use your preferred shell
# open your editor and hack hack hack..
cargo build # build dependencies are loaded in your shell
# or 
nix run github:vic/gleam-nix --override-input gleam path:$PWD -- --help # runs your local `gleam --help`
```

## flake.nix

[Nix flakes] are the secret sauce for nix reproducible builds.
Since all build dependencies get hashed, even the source code.
Every external dependency such external repos (e.g. nixpkgs), 
external utilities (e.g. cargo llvm make), and any Cargo.toml
workspace dependency (read from `Cargo.nix`) gets hashed so that
nix only builds what has actually changed.

If you edit the `flake.nix` file, for example to change the rust
toolchain or the nixpkgs revision, run `nix flake udpate` afterwards
to regenerate the lock file.

## Regenerating `Cargo.nix`

From time to time the `Cargo.nix` file needs to be re-generated
by using [cargo2nix](https://github.com/cargo2nix/cargo2nix)
in order to keep Gleam's cargo deps nix-controlled.

```shell
make generate
```
