{ den, ... }:
{
  den.aspects.THEBATTLESHIP-dante-net = {
    description = "Dante audio network: PTP-conflicting timesyncd off, Dante firewall ports and trusted interfaces";
    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        # --- Dante / Inferno audio network configuration ---

        # Disable systemd-timesyncd — it conflicts with statime-inferno PTP daemon
        services.timesyncd.enable = false;

        # Firewall rules for Dante audio network
        networking.firewall = {
          allowedUDPPorts = [
            319
            320
            4400
            4401
            8800
            4402
            4455
            5353
            8700
            8800
          ];
          # Dante allocates ephemeral receive ports dynamically, so we need
          # the full ephemeral range open on the Dante interface (enp12s0).
          # A more precise approach: trust the dedicated Dante interface.
          trustedInterfaces = [
            "enp12s0"
            "wlp14s0u4i2"
          ];
        };
      };
  };
}
