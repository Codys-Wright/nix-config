# Hardware facet: what every physical machine needs. Machine-specific parts
# are included by the host next to it:
#   <fleet.hardware/nvidia>  <fleet.hardware/cuda>  <fleet.hardware/zsa>
#   <fleet.networking/tailscale>
{
  lib,
  fleet,
  __findFile,
  ...
}:
{
  fleet.hardware = {
    description = "Hardware support configuration";

    # Redistributable firmware (AMD GPU, WiFi, etc.) — needed by most hardware
    nixos.hardware.enableRedistributableFirmware = lib.mkDefault true;

    includes = [
      <fleet.hardware/facter>
      <fleet/audio>
      <fleet.hardware/bluetooth>
      <fleet.networking/networkmanager>
      <fleet.hardware/disk-utils>
    ];
  };
}
