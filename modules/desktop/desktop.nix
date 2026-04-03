# Desktop facet - Provides access to desktop components
{ FTS, ... }:
{
  FTS.desktop.description = ''
    Desktop configuration with environments, bootloaders, and related components.

    Direct access:
      <FTS.desktop/environment/niri>
      (FTS.grub { uefi = true; })
  '';
}
