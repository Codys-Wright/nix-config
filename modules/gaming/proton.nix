# Proton compatibility tools aspect
{
  FTS.gaming._.proton = {
    description = "Proton compatibility tools for running Windows games on Linux";

    homeManager =
      {
        pkgs,
        lib,
        ...
      }:
      lib.mkMerge [
        # Allow dotnet 6.0 (EOL but required for MelonLoader on Il2Cpp games)
        # This needs to be outside mkIf to avoid infinite recursion
        {
          nixpkgs.config.permittedInsecurePackages = [
            "dotnet-runtime-6.0.36"
          ];
        }
        (lib.mkIf (!pkgs.stdenv.isDarwin) {
          home.packages = [
            pkgs.protonup-ng
            pkgs.protonup-rs # Install/update GE-Proton and Wine-GE
            pkgs.protontricks # Run winetricks commands for Proton games
            pkgs.dotnet-runtime_6 # Required for MelonLoader on Il2Cpp games
          ];
          home.sessionVariables = {
            STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
          };
        })
      ];

    nixos = _: {
      # Allow dotnet 6.0 (EOL but required for MelonLoader on Il2Cpp games)
      nixpkgs.config.permittedInsecurePackages = [
        "dotnet-runtime-6.0.36"
      ];
    };
  };
}
