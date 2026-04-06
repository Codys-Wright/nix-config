# Nushell — structured data shell
{
  fleet,
  ...
}:
{
  fleet.coding._.shells._.nushell = {
    description = "Nushell structured data shell with sensible defaults";

    os =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.nushell ];
      };

    homeManager =
      { pkgs, lib, ... }:
      {
        programs.nushell = {
          enable = true;

          # Core settings
          settings = {
            show_banner = false;
            edit_mode = "vi";
            shell_integration = true;
            use_kitty_protocol = true;
            highlight_resolved_externals = true;
            recursion_limit = 50;

            completions = {
              case_sensitive = false;
              quick = true;
              partial = true;
              algorithm = "fuzzy";
            };

            cursor_shape = {
              vi_insert = "line";
              vi_normal = "block";
            };

            history = {
              max_size = 100000;
              sync_on_enter = true;
              file_format = "sqlite";
              isolation = false;
            };

            table = {
              mode = "rounded";
              index_mode = "always";
              trim = {
                methodology = "wrapping";
                wrapping_try_keep_words = true;
              };
            };
          };

          # Aliases matching fish setup
          shellAliases = {
            l = "ls -l";
            ll = "ls -la";
            ".." = "cd ..";
            vp = "nix run ~/.flake#nvf";
          };
        };
      };
  };
}
