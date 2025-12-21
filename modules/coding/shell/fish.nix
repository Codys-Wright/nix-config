# Fish shell aspect with custom configuration
{FTS, ...}: {
  FTS.coding._.shells._.fish = {
    description = "Fish shell with custom configuration and optimizations";

    homeManager = {
      config,
      pkgs,
      lib,
      ...
    }: {
      programs.fish = {
        enable = true;
        interactiveShellInit = ''
          # Unbind Ctrl+l (default clear binding) to allow it to pass through to Zellij
          bind -e \cl
        '';
      };
    };
  };
}
