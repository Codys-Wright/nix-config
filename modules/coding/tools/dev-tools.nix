# General development tools aspect
{ ... }:
{
  den.aspects.dev-tools = {
    description = "General development tools and utilities";

    homeManager =
      { pkgs, lib, ... }:
      lib.mkIf pkgs.stdenvNoCC.isDarwin {
        home.packages = with pkgs; [
          # Build tools
          gnumake
          cmake
          meson
          ninja
          pkg-config

          # Debugging tools
          gdb
          lldb
          # Note: valgrind is Linux-only and not available on macOS/Darwin

          # Performance tools
          hyperfine
          # Note: perf-tools is Linux-only and not available on macOS/Darwin

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

