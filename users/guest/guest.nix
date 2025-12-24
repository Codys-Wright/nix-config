{
  FTS,
  den,
  __findFile,
  ...
}: {
  den = {
    homes = {
      # NixOS home configuration
      x86_64-linux.guest = {
        userName = "guest";
        aspect = "guest";
      };
    };

    # Guest user aspect - minimal configuration without secrets
    aspects.guest = {
      description = "Minimal guest user for bootstrap deployments";

      includes = [
        # Home-manager backup system
        den.aspects.hm-backup
        
        # Basic user setup (no secrets required)
        <FTS.user/admin>
      ];

      # Minimal home-manager config
      homeManager = {pkgs, ...}: {
        home.packages = with pkgs; [
          vim
          htop
          git
        ];
      };
    };
  };
}
