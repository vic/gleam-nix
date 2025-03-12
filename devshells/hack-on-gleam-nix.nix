# for hackin on this repository
{
  pkgs,
  inputs,
  perSystem,
  ...
}:
let
  gleamNix = pkgs.callPackage ../gleam.nix { inherit inputs; };

  treefmt = {
    name = "treefmt";
    help = pkgs.treefmt.meta.description;
    command = ''
      ${pkgs.lib.getExe inputs.self.formatter.${pkgs.system}} "''${@}"
    '';
  };

  generate-gleam-cargo-nix = {
    name = "generate-gleam-cargo-nix";
    help = "Generate Cargo.nix from gleam sources";
    command = ''
      ln -sfn ${gleamNix.cargoNix} ./result
      ln -sfn ${gleamNix.cargoNix}/default.nix ./Cargo.nix
      echo "Generated files at ./result -> ${gleamNix.cargoNix}"
    '';
  };

  show-gleam-version = {
    name = "show-gleam-version";
    help = "Display gleam revision and version";
    command =
      let
        file = pkgs.writeText "gleam.json" (builtins.toJSON gleamNix.versionInfo);
      in
      ''
        ${pkgs.lib.getExe pkgs.jq} -r . ${file}
      '';
  };

  show-rust-version = {
    name = "show-rust-version";
    help = "Display rust revision and version";
    command =
      let
        file = pkgs.writeText "gleam.json" (builtins.toJSON gleamNix.rustVersionInfo);
      in
      ''
        ${pkgs.lib.getExe pkgs.jq} -r . ${file}
      '';
  };

  gh-flake-update = pkgs.writeShellApplication {
    name = "gh-flake-update";
    text = ''
      export LABEL="gleam-update"

      git config --local user.name "Victor Borja"
      git config --local user.email "vborja@apache.org"

      branch="gleam-update-$(date '+%F')"
      git checkout -b "$branch"
      title="Updating gleam input $(date)"

      (
        echo "$title"
        echo -ne "\n\n\n\n"

        echo '```shell'
        echo '$ nix flake update gleam'
        nix flake update gleam --accept-flake-config 2>&1
        echo '```'
        echo -ne "\n\n\n\n"

        echo 'Trying to build with: '
        echo '```json'
        jq -r '.nodes | ({ "gleam": .gleam.locked.rev, "rust": ."rust-manifest".original.url })' flake.lock
        echo '```'
        echo -ne "\n\n\n\n"

        echo 'building gleam... '
        nix develop .#hack-on-gleam-nix --quiet --accept-flake-config -c show-rust-version > /tmp/rust-version.json
        nix develop .#hack-on-gleam-nix --quiet --accept-flake-config -c show-gleam-version > /tmp/built-version.json
        echo "$?" > /tmp/build-status
        if test "0" -eq "$(< /tmp/build-status)"; then
          echo -e '\n_SUCCESS_'

          echo '```json'
          echo '# built-version.json'
          cat /tmp/built-version.json
          echo '```'
        else
          echo -e '\n_FAILURE_'
        fi
        echo -ne "\n\n\n\n"
      ) | tee /tmp/commit-message.md

      gleam_rev="$(jq '.nodes.gleam.locked.rev' flake.lock)"
      rust_url="$(grep "rust-manifest.url = " flake.nix | cut -d= -f2 | tr -d "\"; ")"
      (
        echo "Build of gleam [$gleam_rev](https://github.com/gleam-lang/gleam/tree/$gleam_rev)"
        echo "With rust-manifest: $rust_url"
        echo -ne "\n\n\n\n"
        echo '```json'
        echo '# rust-version.json'
        cat /tmp/rust-version.json
        echo '```'
        echo -ne "\n\n\n\n"
      )  >> /tmp/message.md
      cat /tmp/commit-message.md >> /tmp/message.md

      rust_version="$(jq '.version' /tmp/rust-version.json)"

      if test "0" -eq "$(< /tmp/build-status)"; then
        title="Successfuly built Gleam $gleam_rev";

        gleam_version="$(jq '.gleam.version' /tmp/built-version.json)"

        git status -s | grep 'M ' | cut -d 'M' -f 2 | xargs git add
        git commit -F /tmp/message.md --no-signoff --no-verify --trailer "request-checks:true" --no-edit --cleanup=verbatim
        git push origin "$branch:$branch" --force
        gh pr create --base main --label "$LABEL,success,gleam-$gleam_version,rust-$rust_version" --reviewer "@me" --assignee "@me" --body-file /tmp/message.md --title "$title" --head "$branch" | tee /tmp/pr-url
        gh pr merge "$(< /tmp/pr-url)" --auto --delete-branch --rebase
      else
        title="Failed to build Gleam $gleam_rev";
        gh issue create --label "$LABEL,failure,rust-$rust_version" --assignee "@me" --body-file /tmp/message.md --title "$title" | tee /tmp/issue-url
      fi
    '';
  };

in
perSystem.devshell.mkShell {
  imports = [ "${inputs.devshell}/extra/git/hooks.nix" ];

  devshell.packages = [ gh-flake-update ];

  devshell.motd = ''
    $(${pkgs.lib.getExe pkgs.glow} ${./hack-on-gleam-nix.md})
    $(menu)
  '';

  git.hooks.enable = true;
  git.hooks.pre-commit.text = ''
    treefmt --ci
  '';

  commands = [
    treefmt
    generate-gleam-cargo-nix
    show-gleam-version
    show-rust-version
  ];

}
