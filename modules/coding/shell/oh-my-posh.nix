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
        themeFile = "${pkgs.oh-my-posh}/share/oh-my-posh/themes/catppuccin.omp.json";
        configArg = "--config ${themeFile}";
        # Pre-generate the nushell init script at build time with the theme baked in
        ompInitNu = pkgs.runCommand "oh-my-posh-init.nu" { } ''
          ${lib.getExe pkgs.oh-my-posh} init nu ${configArg} --print > $out
        '';
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

        # Set POSH_THEME so oh-my-posh uses catppuccin at runtime
        # The init script's `print` commands read this env var
        programs.nushell.environmentVariables.POSH_THEME = themeFile;

        # Source the pre-built init script
        programs.nushell.extraConfig = lib.mkOrder 2000 ''
          source ${ompInitNu}
        '';
      };
  };
}
