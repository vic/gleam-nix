# for hackin on gleam sources
{
  pkgs,
  inputs,
  perSystem,
  ...
}:
let
  gleamNix = pkgs.callPackage ../gleam.nix { inherit inputs; };

  glow = pkgs.lib.getExe pkgs.glow;
  gum = pkgs.lib.getExe pkgs.gum;

  contributingCommand = {
    name = "contributing";
    help = "About contributing to gleam.";
    command = ''
      ${glow} -p ${inputs.gleam}/CONTRIBUTING.md
    '';
  };

  codeOfConductCommand = {
    name = "code-of-conduct";
    help = "Gleam's code of conduct.";
    command = ''
      ${glow} -p ${inputs.gleam}/CODE_OF_CONDUCT.md
    '';
  };

  confirm-gen-envrc = ''
    No .envrc found.

    Would you like me to generate one?

  '';

in
perSystem.devshell.mkShell {

  devshell.packages = pkgs.lib.attrValues gleamNix.gleamDevPackages;
  devshell.packagesFrom = [ gleamNix ];

  commands = [
    {
      help = pkgs.cargo.meta.description;
      package = gleamNix.gleamDevPackages.cargo;
    }

    contributingCommand
    codeOfConductCommand
  ];

  devshell.motd = ''
    $(${glow} ${./hack-on-gleam.md})

    $(menu)
  '';

  devshell.interactive.gen-envrc.text = ''
    # if direnv is available and no .envrc file is found, ask to generate one.
    if (type -p direnv 2>&1>/dev/null) && (! test -f .envrc) && (${gum} confirm "${confirm-gen-envrc}"); then
      echo .envrc  >> .git/info/exclude
      echo .direnv >> .git/info/exclude
      echo "use flake github:vic/gleam-nix#hack-on-gleam" >> .envrc
      direnv allow
    fi
  '';

}
