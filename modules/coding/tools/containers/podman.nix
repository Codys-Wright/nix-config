# Podman container tools aspect
{FTS, ...}: {
  FTS.coding._.tools._.containers._.podman = {
    description = "Podman container tools with Docker compatibility";

    nixos = {pkgs, ...}: {
      # Enable Podman
      virtualisation.podman = {
        enable = true;
        # Enable Docker compatibility
        dockerCompat = true;
        # Enable Docker socket for compatibility
        dockerSocket.enable = true;
      };

      # Set Podman as the OCI containers backend
      virtualisation.oci-containers.backend = "podman";

      # Enable Podman Compose for Docker Compose compatibility
      environment.systemPackages = with pkgs; [
        podman-compose
      ];

      # Set DOCKER_HOST for Docker Compose compatibility
      environment.extraInit = ''
        export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock
      '';
    };

    homeManager = {
      pkgs,
      lib,
      ...
    }: {
      home.packages = with pkgs; [
        lazydocker
      ];
    };
  };
}

