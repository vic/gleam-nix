If you change `inputs.rust-manifest.url` on `flake.nix`,
be sure to provide the output of the following command
in your pull-request.

```
nix develop .#hack-on-gleam-nix --accept-flake-config -c show-gleam-version
```

_Happy hacking!_
