# Podman container tools aspect
{FTS, ...}: {
  FTS.coding._.tools._.containers._.podman = {
    description = "Podman container tools with Docker compatibility";

    nixos = {pkgs, ...}: {
      # Enable containers
      virtualisation.containers.enable = true;

      # Enable Podman with Docker compatibility
      virtualisation.podman = {
        enable = true;
        dockerCompat = true;
        dockerSocket.enable = true;
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

      # Create podman group for rootless container access
      users.groups.podman = {};

      # Add user to podman group for rootless container access
      # Note: This assumes the user is "cody" - in a multi-user setup,
      # this would need to be parameterized
      users.users.cody.extraGroups = ["podman"];
    };

    homeManager = {
      pkgs,
      lib,
      ...
    }: {
      home.packages = with pkgs; [
        lazydocker
      ];

      # Set DOCKER_HOST environment variable for Docker Compose compatibility
      home.sessionVariables = {
        DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/podman/podman.sock";
      };

      # Configure shells to set DOCKER_HOST
      programs.fish.shellInit = ''
        set -x DOCKER_HOST unix://$XDG_RUNTIME_DIR/podman/podman.sock
      '';

      programs.zsh.initExtra = ''
        export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock
      '';
    };
  };
}
