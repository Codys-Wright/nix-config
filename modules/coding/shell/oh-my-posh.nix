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

        # Pre-generate the nushell init script at build time, patching in the
        # --config flag on every `print` call so the theme is used at runtime.
        # Without this, oh-my-posh falls back to the default theme because
        # its cache (created during `init`) doesn't persist from the nix sandbox.
        ompInitNu = pkgs.runCommand "oh-my-posh-init.nu" { } ''
          ${lib.getExe pkgs.oh-my-posh} init nu ${configArg} --print \
            | ${pkgs.gnused}/bin/sed 's|print \$type|print $type ${configArg}|g' \
            | ${pkgs.gnused}/bin/sed 's|print secondary|print secondary ${configArg}|g' \
            > $out
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

        # Source the pre-built and patched init script
        programs.nushell.extraConfig = lib.mkOrder 2000 ''
          source ${ompInitNu}
        '';
      };
  };
}
