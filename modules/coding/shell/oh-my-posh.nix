# Oh My Posh prompt theme configuration
{
  fleet,
  ...
}:
{
  fleet.coding._.shells._.oh-my-posh = {
    description = "Oh My Posh prompt theme with custom configuration";
    os =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.oh-my-posh ];
      };

    homeManager =
      { pkgs, lib, ... }:
      let
        configArg = "--config ${pkgs.oh-my-posh}/share/oh-my-posh/themes/catppuccin.omp.json";
      in
      {
        programs.oh-my-posh = {
          enable = true;
          enableFishIntegration = true;
          enableBashIntegration = true;
          # Disable HM's broken nushell integration — we handle it below
          enableNushellIntegration = false;
          enableZshIntegration = true;
          useTheme = "catppuccin";
        };

        # Proper nushell oh-my-posh integration:
        # Generate the init script to a file, then source it.
        # HM's built-in integration just dumps the bare command which nushell doesn't eval.
        programs.nushell.extraEnv = ''
          ${lib.getExe pkgs.oh-my-posh} init nu ${configArg} --env-file ~/.cache/oh-my-posh/init.nu
        '';
        programs.nushell.extraConfig = lib.mkOrder 2000 ''
          source ~/.cache/oh-my-posh/init.nu
        '';
      };
  };
}
