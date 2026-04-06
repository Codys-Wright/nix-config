# Podman container tools aspect
{ FTS, den, ... }:
{
  FTS.coding._.tools._.containers._.podman = {
    description = "Podman container tools with Docker compatibility";

    includes = [ (den.lib.groups [ "podman" ]) ];

    nixos =
      { pkgs, ... }:
      {
        # Enable containers
        virtualisation.containers.enable = true;

        # Enable Podman with Docker compatibility
        virtualisation.podman = {
          enable = true;
          defaultNetwork.settings.dns_enabled = true;
        };

        # Set Podman as the OCI containers backend
        virtualisation.oci-containers.backend = "podman";

        # Enable Podman Compose and Docker Compose for compatibility
        environment.systemPackages = with pkgs; [
          docker-compose
          podman-compose
          podman-tui
        ];

        # Suppress the external compose provider warning message
        environment.etc."containers/containers.conf.d/compose.conf".text = ''
          [engine]
          compose_warning_logs = false
        '';

        # Create podman group for rootless container access
        users.groups.podman = { };
      };

    homeManager =
      {
        pkgs,
        lib,
        ...
      }:
      {
        home.packages = with pkgs; [
          lazydocker
        ];

      };
  };
}
