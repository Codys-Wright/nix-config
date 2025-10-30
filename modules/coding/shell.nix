# Shell configuration aspect for CodyWright's development environment
{ ... }:
{
  den.aspects.shell-tools = {
    description = "Shell configuration and tools";

    homeManager =
          { pkgs, lib, ... }:
          lib.mkIf pkgs.stdenvNoCC.isDarwin {
            # Zsh configuration
            programs.zsh = {
              enable = true;
              autosuggestion.enable = true;
              enableCompletion = true;
              historySubstringSearch.enable = true;
              syntaxHighlighting.enable = true;

              initContent = ''
                # Fix an issue with tmux.
                export KEYTIMEOUT=1

                # Use vim bindings.
                set -o vi

                export EDITOR="nvim"

                export NIX_LD=$(nix eval --impure --raw --expr 'let pkgs = import <nixpkgs> {}; NIX_LD = pkgs.lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker"; in NIX_LD')

                export CC=clang
                export CXX=clang++

                # Colcon build configuration
                CLANG_BASE="--build-base build_clang --install-base install_clang"
                BUILD_ARGS="--symlink-install $CLANG_BASE --cmake-args -DCMAKE_EXPORT_COMPILE_COMMANDS=ON"
                alias cb="colcon build $BUILD_ARGS"
              '';

              shellAliases = {
                vim = "nvim";
                vi = "nvim";
                v = "nvim";
                ls = "eza --icons=always --no-quotes";
                tree = "eza --icons=always --tree --no-quotes";
              };

              plugins = [
                {
                  name = "powerlevel10k";
                  src = pkgs.zsh-powerlevel10k;
                  file = "./powerlevel10k.zsh-theme";
                }
              ];
            };

            # Starship prompt configuration
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
                  style = "bg:#ff9e64";
                  format = "[ $symbol $context ]($style) $path";
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
                nodejs = {
                  symbol = "";
                  style = "bg:#51afef";
                  format = "[[ $symbol( $version) ](fg:#1e1e1e bg:#51afef)]($style)";
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

            # Powerlevel10k is already configured above in the zsh plugins

            # Additional shell packages
            home.packages = with pkgs; [ yazi ];
          };
  };
}
