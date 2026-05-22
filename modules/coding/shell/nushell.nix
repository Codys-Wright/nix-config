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
            use_kitty_protocol = true;
            highlight_resolved_externals = true;
            recursion_limit = 50;

            shell_integration = {
              osc2 = true;
              osc7 = true;
              osc8 = true;
              osc9_9 = false;
              osc133 = true;
              osc633 = true;
              reset_application_mode = true;
            };

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

          # PATH additions for user-managed package managers (cargo, npm,
          # pnpm). Lets external launchers like Claude Code MCP servers
          # (dioxus-mcp from `cargo install`, claude from the npm installer)
          # find their binaries when spawned from a nushell session.
          # Nushell's $env.PATH is a list, not a colon-string, so this goes
          # into env.nu via extraEnv (loaded before config.nu).
          extraEnv = ''
            $env.PATH = ($env.PATH | split row (char esep)
              | prepend $"($env.HOME)/.cargo/bin"
              | prepend $"($env.HOME)/.local/bin"
              | prepend $"($env.HOME)/.npm-global/bin"
              | prepend $"($env.HOME)/.local/share/pnpm"
              | uniq)
          '';
        };
      };
  };
}
