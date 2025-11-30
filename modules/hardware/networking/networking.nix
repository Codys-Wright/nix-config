# Networking hardware aspect
{
  FTS,
  ...
}:
{
  FTS.networking = {
    description = "NetworkManager networking support";

    nixos = { ... }: {
      networking = {
        networkmanager.enable = true;
      };

      # Enable network manager applet
      programs.nm-applet.enable = true;

      # Disable systemd network wait-online
      systemd.network.wait-online.enable = false;

      # environment.systemPackages = [
      #     pkgs.linuxKernel.packages.linux_zen.rtl8821au
      # ];

      # # specific tp-link driver
      # boot.extraModulePackages = with config.boot.kernelPackages; [
      #   rtl8821au
      #   rtl8821cu
      # ];
    };
  };
}

