{ den, ... }:
{
  den.aspects.THEBATTLESHIP-dante-net = {
    description = "Dante audio network: timesyncd for the system clock, Dante firewall ports and trusted interfaces";
    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        # --- Dante / Inferno audio network configuration ---

        # Keep systemd-timesyncd on. statime-inferno runs with
        # `virtual-system-clock = true` (based on monotonic_raw), so PTP never
        # disciplines CLOCK_REALTIME and the two don't conflict. Without an NTP
        # client the wall clock drifted 70 s, which broke T3 Connect's relay
        # proofs (60 s skew limit). Captain approved re-enabling (STA-425).
        services.timesyncd.enable = true;

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
