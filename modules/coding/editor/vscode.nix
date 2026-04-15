# VS Code editor aspect
{
  fleet,
  ...
}:
{
  fleet.coding._.editors._.vscode = {
    description = "Visual Studio Code editor";

    homeManager =
      {
        pkgs,
        lib,
        ...
      }:
      {
        programs.vscode = {
          enable = true;
          package = pkgs.vscode;
        };
      };
  };
}
