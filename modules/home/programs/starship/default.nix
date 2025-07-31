{
  options,
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.programs.starship;
  stylix = config.lib.stylix.colors;
in
{
  options.${namespace}.programs.starship = with types; {
    enable = mkBoolOpt false "Enable starship";
  };

  config = mkIf cfg.enable {
    programs.starship = {
      enable = true;
      settings = {
        command_timeout = 5000;
        format = concatStrings [
          "[](#${stylix.base03})"
          "$os"
          "$username"
          "[](bg:#${stylix.base09} fg:#${stylix.base03})"
          "$directory"
          "[](fg:#${stylix.base09} bg:#${stylix.base0B})"
          "$git_branch"
          "$git_status"
          "[](fg:#${stylix.base0B} bg:#${stylix.base0C})"
          "$c"
          "$rust"
          "$golang"
          "$nodejs"
          "$php"
          "$java"
          "$kotlin"
          "$haskell"
          "$python"
          "[](fg:#${stylix.base0C} bg:#${stylix.base0D})"
          "$docker_context"
          "[](fg:#${stylix.base0D} bg:#${stylix.base0E})"
          "$time"
          "[ ](fg:#${stylix.base0E})"
          "$line_break"
          "$character"
        ];
        os = {
          disabled = false;
          style = "bg:#${stylix.base03} fg:#${stylix.base05}";
          symbols = {
            Windows = "󰍲";
            Ubuntu = "󰕈";
            SUSE = "";
            Raspbian = "󰐿";
            Mint = "󰣭";
            Macos = "";
            Manjaro = "";
            Linux = "󰌽";
            Gentoo = "󰣨";
            Fedora = "󰣛";
            Alpine = "";
            Amazon = "";
            Android = "";
            Arch = "󰣇";
            Artix = "󰣇";
            CentOS = "";
            Debian = "󰣚";
            Redhat = "󱄛";
            RedHatEnterprise = "󱄛";
            NixOS = "󱄅";
          };
        };
        username = {
          show_always = true;
          style_user = "bg:#${stylix.base03} fg:#${stylix.base05}";
          style_root = "bg:#${stylix.base03} fg:#${stylix.base05}";
          format = "[ $user ]($style)";
        };
        directory = {
          style = "bg:#${stylix.base09} fg:#${stylix.base01}";
          format = "[ $path ]($style)";
          truncation_length = 3;
          truncation_symbol = "…/";
          substitutions = {
            "Documents" = "󰈙 ";
            "Downloads" = " ";
            "Music" = " ";
            "Pictures" = " ";
            "Developer" = "󰲋 ";
          };
        };

        c = {
          symbol = " ";
          style = "bg:#${stylix.base0C}";
          format = " $symbol ($version) ]($style)";
        };

        docker_context = {
          symbol = " ";
          style = "bg:#${stylix.base0E}";
          format = "[ $symbol $context ]($style) $path";
        };

        elixir = {
          symbol = " ";
          style = "bg:#${stylix.base0C}";
          format = "[ $symbol ($version) ]($style)";
        };

        elm = {
          symbol = " ";
          style = "bg:#${stylix.base0C}";
          format = "[ $symbol ($version) ]($style)";
        };

        git_branch = {
          symbol = "";
          style = "bg:#${stylix.base0C}";
          format = "[[ $symbol $branch ](fg:#${stylix.base02} bg:#${stylix.base0B})]($style)";
        };

        git_status = {
          style = "bg:#${stylix.base0C}";
          format = "[[($all_status$ahead_behind )](fg:#${stylix.base02} bg:#${stylix.base0B})]($style)";
        };

        golang = {
          symbol = " ";
          style = "bg:#${stylix.base0C}";
          format = "[ $symbol ($version) ]($style)";
        };

        haskell = {
          symbol = " ";
          style = "bg:#${stylix.base0C}";
          format = "[ $symbol ($version) ]($style)";
        };

        java = {
          symbol = " ";
          style = "bg:#${stylix.base0C}";
          format = "[ $symbol ($version) ]($style)";
        };

        julia = {
          symbol = " ";
          style = "bg:#${stylix.base0C}";
          format = "[ $symbol ($version) ]($style)";
        };

        nodejs = {
          symbol = "";
          style = "bg:#${stylix.base0C}";
          format = "[[ $symbol( $version) ](fg:#${stylix.base02} bg:#${stylix.base0C})]($style)";
        };

        nim = {
          symbol = " ";
          style = "bg:#${stylix.base0C}";
          format = "[ $symbol ($version) ]($style)";
        };

        python = {
          style = "bg:#${stylix.base0C}";
          format = "[(\($virtualenv\) )]($style)";
        };

        rust = {
          symbol = "";
          style = "bg:#${stylix.base0C}";
          format = "[ $symbol ($version) ]($style)";
        };

        time = {
          disabled = false;
          time_format = "%R"; # Hour:Minute Format
          style = "bg:#${stylix.base09}";
          format = "[[  $time ](fg:#${stylix.base02} bg:#${stylix.base0E})]($style)";
        };

        line_break = {
          disabled = false;
        };

        character = {
          disabled = false;
          success_symbol = "[](bold fg:#${stylix.base0B})";
          error_symbol = "[](bold fg:#${stylix.base08})";
          vimcmd_symbol = "[](bold fg:#${stylix.base05})";
          vimcmd_replace_one_symbol = "[](bold fg:#${stylix.base0E})";
          vimcmd_replace_symbol = "[](bold fg:#${stylix.base0E})";
          vimcmd_visual_symbol = "[](bold fg:#${stylix.base07})";
        };
      };
    };
  };
}
