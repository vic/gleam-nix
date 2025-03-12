# Gleam on Nix

This repo provides packages and [development shells][devshell] for
working with [Gleam] projects using Nix.

## Usage

```
# running `gleam --version`
$ nix run github:vic/gleam-nix -- --version
gleam 1.9.0

# you can also override to use any gleam revision (commit,branch,release) and any rust version (prefer stable releases)
$ nix run github:vic/gleam-nix --override-input gleam github:gleam-lang/gleam/v1.9.1 --override-input rust-manifest file+https://static.rust-lang.org/dist/channel-rust-1.85.0.toml -- --version
gleam 1.9.1
```

> For previous versions see [Historic Builds](https://github.com/vic/gleam-nix/wiki/Historic-Builds)

### Hack with Gleam

If you are creating a new awesome project with Gleam,
this flake can provide you with a development environment
containing `gleam` and two of its run-times: `erlang` and `nodejs`.

```
$ nix run github:vic/gleam-nix -- new my-new-project
$ cd my-new-project
$ nix develop github:vic/gleam-nix -c $SHELL -l
```

If you are using [direnv], create an `.envrc` file with
the following content:

```shell
# .envrc
use flake github:vic/gleam-nix
```

### Hack on Gleam

If you are willing to contribute to Gleam development,
this flake can provide you an entire development environment
ready for you to focus only on making Gleam awesome.

```shell
$ git clone https://github.com/gleam-lang/gleam
$ cd gleam
$ nix develop github:vic/gleam-nix#hack-on-gleam --override-input gleam "path:$PWD" -c $SHELL -l
```

If you are using [direnv], create an `.envrc` file with
the following content:

```shell
# .envrc
use flake github:vic/gleam-nix#hack-on-gleam --override-input gleam "path:$PWD"
```

### Hack on this repo

```shell
$ nix develop .#hack-on-gleam-nix -c $SHELL -l
```

If you are using [direnv] this repo already contains an `.envrc` you can load.

## Contributing

Yes, please :).

See [hack-on-gleam-nix](devshells/hack-on-gleam-nix.md)

Try not to change `gleam` pinned release unless it no longer builds with
the current Rust toolchain. In that case, update the `rust-manifest` input
*and* the `gleam` pinned release. And please update [Historic Builds](https://github.com/vic/gleam-nix/wiki/Historic-Builds) with the range of known versions able to build.

## FAQ

- How is this different from the `gleam` package provided by `nixpkgs`.

  This flake existed before we had an official `gleam` package on `nixpkgs`.
  And most people would indeed only use that package.

  However, for gleam hackers, this flake would be better suited since
  it provides a development shell with dependencies based on Gleam's source.

  Also people trying to use a more recent or experimental version of Gleam
  will benefit from this flake.

- I'm getting a `option 'allow-import-from-derivation' is disabled` error.

  Old versions of this repo bundled a `Cargo.nix` file containing all of Gleam's
  dependencies in order for nix to know how to fetch them and how to build the
  Gleam cargo workspace.

  However, one inconvenience of this was that the `Cargo.nix` file was tied to
  a particular Gleam revision, and since Gleam is improving quite rapidly, it
  was not uncommon to find the `Cargo.nix` file on this repo being outdated with
  respect to Gleam's source code.

  People had to regularly re-create the `Cargo.nix` file with `cargo2nix`.

  Now, instead of using `cargo2nix`, we use `crate2nix` which allows us to generate
  the `Cargo.nix` file as part of the build. Thus not requiring we to bundle it
  on this repo, and prevent it from getting outdated. One advantage is that using
  `--override-input gleam <some-gleam-url>` will automatically generate `Cargo.nix`
  for that particular gleam revision.

  This repo will only need to be updated when we have to bump the rust toolchain
  as expected by Gleam.

  On the other side, by not bundling a `Cargo.nix`, building with `crate2nix`
  requires the `allow-import-from-derivation` nix option to be enabled.

  This flake enables this option as part of `flake.nix` and will
  be activated if you are listed as trusted-user in your `nix.conf` or
  provide `--accept-flake-config` explicitly.

[devshell]: https://numtide.github.io/devshell
[direnv]: https://direnv.net
[gleam]: https://gleam.run
