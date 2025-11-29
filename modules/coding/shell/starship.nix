# Starship shell prompt aspect
{
  FTS, ... }:
{
  FTS.starship = {
    description = "Starship shell prompt with custom configuration";

    homeManager = { config, pkgs, lib, ... }: {
      programs.starship = {
        enable = true;
        settings = {
          command_timeout = 5000;
          format = lib.concatStrings [
            "[ ](#666666)"
            "$os"
            "$username"
            "[ ](bg:#ff6c6b fg:#666666)"
            "$directory"
            "[ ](fg:#ff6c6b bg:#98be65)"
            "$git_branch"
            "$git_status"
            "[ ](fg:#98be65 bg:#51afef)"
            "$c"
            "$rust"
            "$golang"
            "$nodejs"
            "$php"
            "$java"
            "$kotlin"
            "$haskell"
            "$python"
            "[ ](fg:#51afef bg:#c678dd)"
            "$docker_context"
            "[ ](fg:#c678dd bg:#ff9e64)"
            "$time"
            "[ ](fg:#ff9e64)"
            "$line_break"
            "$character"
          ];
          os = {
            disabled = false;
            style = "bg:#666666 fg:#ffffff";
            symbols = {
              Windows = "󰍲";
              Ubuntu = "󰕈";
              SUSE = "󰣭";
              Raspbian = "󰐿";
              Mint = "󰣭";
              Macos = "󰀵";
              Manjaro = "󰣉";
              Linux = "󰌽";
              Gentoo = "󰣨";
              Fedora = "󰣛";
              Alpine = "󰣇";
              Amazon = "󰢮";
              Android = "󰀲";
              Arch = "󰣇";
              Artix = "󰣇";
              CentOS = "󰌽";
              Debian = "󰣚";
              Redhat = "󱄛";
              RedHatEnterprise = "󱄛";
              NixOS = "󱄅";
            };
          };
          username = {
            show_always = true;
            style_user = "bg:#666666 fg:#ffffff";
            style_root = "bg:#666666 fg:#ffffff";
            format = "[ $user ]($style)";
          };
          directory = {
            style = "bg:#ff6c6b fg:#1e1e1e";
            format = "[ $path ]($style)";
            truncation_length = 3;
            truncation_symbol = "…/";
            substitutions = {
              "Documents" = " ";
              "Downloads" = " ";
              "Music" = " ";
              "Pictures" = " ";
              "Developer" = " ";
            };
          };

          c = {
            symbol = " ";
            style = "bg:#51afef";
            format = " $symbol ($version) ]($style)";
          };

          docker_context = {
            symbol = " ";
            style = "bg:#c678dd";
            format = "[ $symbol $context ]($style) $path";
          };

          elixir = {
            symbol = " ";
            style = "bg:#51afef";
            format = "[ $symbol ($version) ]($style)";
          };

          elm = {
            symbol = " ";
            style = "bg:#51afef";
            format = "[ $symbol ($version) ]($style)";
          };

          git_branch = {
            symbol = "";
            style = "bg:#51afef";
            format = "[[ $symbol $branch ](fg:#1e1e1e bg:#98be65)]($style)";
          };

          git_status = {
            style = "bg:#51afef";
            format = "[[($all_status$ahead_behind )](fg:#1e1e1e bg:#98be65)]($style)";
          };

          golang = {
            symbol = " ";
            style = "bg:#51afef";
            format = "[ $symbol ($version) ]($style)";
          };

          haskell = {
            symbol = " ";
            style = "bg:#51afef";
            format = "[ $symbol ($version) ]($style)";
          };

          java = {
            symbol = " ";
            style = "bg:#51afef";
            format = "[ $symbol ($version) ]($style)";
          };

          julia = {
            symbol = " ";
            style = "bg:#51afef";
            format = "[ $symbol ($version) ]($style)";
          };

          nodejs = {
            symbol = "";
            style = "bg:#51afef";
            format = "[[ $symbol( $version) ](fg:#1e1e1e bg:#51afef)]($style)";
          };

          nim = {
            symbol = " ";
            style = "bg:#51afef";
            format = "[ $symbol ($version) ]($style)";
          };

          python = {
            style = "bg:#51afef";
            format = "[(\($virtualenv\) )]($style)";
          };

          rust = {
            symbol = "";
            style = "bg:#51afef";
            format = "[ $symbol ($version) ]($style)";
          };

          time = {
            disabled = false;
            time_format = "%R"; # Hour:Minute Format
            style = "bg:#ff6c6b";
            format = "[[  $time ](fg:#1e1e1e bg:#ff9e64)]($style)";
          };

          line_break = {
            disabled = false;
          };

          character = {
            disabled = false;
            success_symbol = "[ ](bold fg:#98be65)";
            error_symbol = "[ ](bold fg:#ff6c6b)";
            vimcmd_symbol = "[ ](bold fg:#ffffff)";
            vimcmd_replace_one_symbol = "[ ](bold fg:#ff9e64)";
            vimcmd_replace_symbol = "[ ](bold fg:#ff9e64)";
            vimcmd_visual_symbol = "[ ](bold fg:#c678dd)";
          };
        };
      };

      # Additional packages for starship features
      home.packages = with pkgs; [
        starship
      ];
    };
  };
}
