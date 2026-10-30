# General development tools aspect
{ fleet, ... }:
{
  fleet.coding._.tools._.dev-tools = {
    description = "General development tools and utilities";

    # NixOS-specific tools (Linux-only)
    provides.to-hosts.nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          # Linux-only debugging tools
          valgrind
          # Linux-only performance tools
          perf-tools
        ];
      };

    # Darwin-specific tools (macOS-only)
    provides.to-hosts.darwin =
      { pkgs, ... }:
      {
        # Add Darwin-specific tools here if needed
      };

    # Cross-platform tools via Home Manager
    homeManager =
      {
        pkgs,
        lib,
        ...
      }:
      {
        home.packages =
          with pkgs;
          [
            # Build tools
            gnumake
            cmake
            meson
            ninja
            pkg-config

            # Debugging tools
            lldb
          ]
          ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
            gdb

            # Performance tools
            hyperfine

            # Documentation
            pandoc
            graphviz

            # Text processing
            jq
            yq-go # Go version of yq (mikefarah/yq) for YAML editing with anchor support-go
            xmlstarlet

            # Network tools
            curl
            wget
            httpie
            netcat
            nmap
            wireshark

            # Archive tools
            unzip
            zip
            p7zip

            # Development utilities
            watchman
            entr
            screen
          ];
      };
  };
}
