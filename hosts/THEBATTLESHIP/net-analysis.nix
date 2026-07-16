{ den, ... }:
{
  den.aspects.THEBATTLESHIP-net-analysis = {
    description = "Packet capture tooling: wireshark, permissive dumpcap wrapper, sniffing CLI tools";
    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        programs.wireshark = {
          enable = true;
          package = pkgs.wireshark;
        };
        # Permissive dumpcap wrapper so the agent shell (started before
        # the wireshark group landed) can capture without re-login.
        security.wrappers.dumpcap-any = {
          source = "${pkgs.wireshark}/bin/dumpcap";
          capabilities = "cap_net_raw,cap_net_admin+eip";
          owner = "root";
          group = "root";
          permissions = "u+rx,g+rx,o+rx";
        };
        environment.systemPackages = with pkgs; [
          iw
          hostapd
          dnsmasq
          tcpdump
          dsniff
          bettercap
          aircrack-ng
          ethtool # I226-V EEE-off recovery + manual debugging

          # ── Realtime-audio diagnostics / tuning ──
          rt-tests # cyclictest — worst-case scheduling jitter
          jack-example-tools # jack_iodelay (round-trip), jack_lsp -L (port latency)
          stress-ng # load generator for cyclictest-under-load
          cpufrequtils # cpupower — inspect / pin CPU frequency
          # rtcqs (realTimeConfigQuickScan) isn't in nixpkgs; thin wrapper runs
          # it from PyPI via uv (downloads on first use, then cached).
          uv
          (writeShellScriptBin "rtcqs" ''exec ${uv}/bin/uvx rtcqs "$@"'')
        ];
      };
  };
}
