# General development tools aspect
{
  FTS, ... }:
{
  FTS.dev-tools = {
    description = "General development tools and utilities";

    # NixOS-specific tools (Linux-only)
    nixos = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        # Linux-only debugging tools
        valgrind
        # Linux-only performance tools
        perf-tools
      ];
    };

    # Darwin-specific tools (macOS-only)
    darwin = { pkgs, ... }: {
      # Add Darwin-specific tools here if needed
    };

    # Cross-platform tools via Home Manager
    homeManager =
      { pkgs, lib, ... }:
      {
        home.packages = with pkgs; [
          # Build tools
          gnumake
          cmake
          meson
          ninja
          pkg-config

          # Debugging tools (cross-platform)
          gdb
          lldb

          # Performance tools
          hyperfine

          # Documentation
          pandoc
          graphviz

          # API development
          postman
          insomnia

          # Text processing
          jq
          yq
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

