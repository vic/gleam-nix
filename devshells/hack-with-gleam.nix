# for hackin with gleam on your stuff
{
  pkgs,
  perSystem,
  ...
}:
perSystem.devshell.mkShell {
  commands = [
    {
      name = "gleam";
      help = pkgs.gleam.meta.description;
      package = perSystem.self.gleam;
    }
  ];
}
