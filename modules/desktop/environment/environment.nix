# Desktop environment facet
{ fleet, ... }:
{
  fleet.desktop._.environment.description = ''
    Desktop environment configuration.

    Direct access:
      <fleet.desktop/environment/niri>
  '';

  fleet.desktop._.environment = { };
}
