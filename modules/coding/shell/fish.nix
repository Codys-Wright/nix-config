# Fish shell aspect with custom configuration
{
  FTS,
  lib,
  ...
}: {
  FTS.coding._.shells._.fish = {
    description = "Fish shell with custom configuration, abbreviations, aliases, and functions";

    homeManager = {
      config,
      pkgs,
      ...
    }: {
      programs.fish = {
        enable = true;

        # Shell abbreviations (expand on space/enter)
        shellAbbrs = {
          # Basic tool replacements
          ls = "exa";
          top = "btm";
          cat = "bat";
          grep = "rg";
          find = "fd";
          nr = "nix run";
          nf = "fd --glob '*.nix' -X nixfmt {}";

          # Vim with cursor position
          vir = {
            expansion = "nvim -c \"'0%\"";
            setCursor = true;
          };
          vt = {
            expansion = "nvim -c \":Tv %\"";
            setCursor = true;
          };

          # jj (Jujutsu VCS)
          jz = "jj-fzf";
          lj = "lazyjj";
          jb = "jj bookmark";
          jc = "jj commit -i";
          jD = {
            expansion = "jj describe -m \"%\"";
            setCursor = true;
          };
          jd = "jj diff --git | diffnav";
          jdg = "jj diff --git";
          je = "jj edit";
          jf = "jj git fetch";
          jg = "jj git";
          jl = "jj log";
          jll = "jj ll";
          jm = "jj bookmark set main -r @";
          "jm-" = "jj bookmark set main -r @-";
          jn = "jj new";
          jN = {
            expansion = "jj new -m \"%\"";
            setCursor = true;
          };
          jp = "jj git push";
          jP = "jj git push && jj new -A main";
          jr = "jj rebase";
          jR = "jj restore -i";
          jS = "jj squash -i";
          js = "jj show --stat --no-pager";
          jss = "jj show --summary --no-pager";
          ju = "jjui";
          jdp = "jj-desc && jj bookmark set main -r @ && jj git push -r main";
          jcp = "jj commit -i && jj bookmark set main -r @- && jj git push -r main";

          # git
          lg = "lazygit";
          gr = "git recents";
          gc = "git commit";
          gb = "git branch";
          gd = "git dff";
          gs = "git status";
          gco = "git checkout";
          gcb = "git checkout -b";
          gp = "git pull --rebase --no-commit";
          gz = "git stash";
          gza = "git stash apply";
          gfp = "git push --force-with-lease";
          gfap = "git fetch --all -p";
          groh = "git rebase remotes/origin/HEAD";
          grih = "git rebase -i remotes/origin/HEAD";
          grom = "git rebase remotes/origin/master";
          grim = "git rebase -i remotes/origin/master";
          gpfh = "git push --force-with-lease origin HEAD";
          gfix = "git commit --all --fixup amend:HEAD";
          gcm = "git commit --all --message";
          ga = "git commit --amend --reuse-message HEAD --all";
          gcam = "git commit --amend --all --message";
          gbDm = "git rm-merged";

          # Magit
          ms = "mg SPC g g";
          mc = "mg SPC g / c";
          md = "mg SPC g / d u";
          ml = "mg SPC g / l l";
          mr = "mg SPC g / r i";
          mz = "mg SPC g / Z l";
        };

        # Shell aliases (simple command replacements)
        shellAliases = {
          y = "EDITOR=d yazi";
          l = "eza -l";
          ll = "eza -l -@ --git";
          tree = "eza -T";
          "." = "eval (history | head -1 | string replace -r '^\\s*\\d+\\s+' '')";
          ".." = "cd ..";
          vs = ''vim -c "lua Snacks.picker.smart()"'';
          vf = ''vim -c "lua Snacks.picker.files()"'';
          vg = ''vim -c "lua Snacks.picker.grep()"'';
          vr = ''vim -c "lua Snacks.picker.recent()"'';
          vd = ''vim -c "DiffEditor $left $right $output"'';
          av = "astrovim";
          lv = "lazyvim";
          vp = "nix run ~/.flake#nvf";
        };

        # Custom fish functions
        functions = {
          # jj functions
          jj-git-init = {
            description = "init jj to follow git branch";
            argumentNames = ["branch"];
            body = ''
              jj git init --colocate
              jj bookmark track "$branch@origin"
              jj config set --repo "revset-aliases.'trunk()'" "$branch@origin"
            '';
          };

          jj-desc = {
            body = ''
              jj describe --edit -m "$(echo -e "\n")$(jj status --color never | awk '{print "JJ: " $0}')$(echo -e "\n")$(jj show --git --color never  | awk '{print "JJ: " $0}')"
            '';
          };

          # Emacs/Spacemacs helpers
          mg = {
            body = ''spc u SPC gg -r "$PWD" RET'';
          };
          spc = {
            body = "SPC $argv -- -nw";
          };
          vspc = {
            body = "SPC $argv -- -c";
          };

          # Vi-style bindings that inherit emacs-style bindings
          fish_hybrid_key_bindings = {
            description = "Vi-style bindings that inherit emacs-style bindings in all modes";
            body = ''
              for mode in default insert visual
                  fish_default_key_bindings -M $mode
              end
              fish_vi_key_bindings --no-erase
            '';
          };

          # Vix helpers (legacy)
          vix-activate = {
            description = "Activate a new vix system generation";
            body = "nix run /hk/vix";
          };
          vix-shell = {
            description = "Run nix shell with vix's nixpkgs";
            body = "nix shell --inputs-from $HOME/.nix-out/nixpkgs";
          };
          vix-nixpkg-search = {
            description = "Nix search on vix's nixpkgs input";
            body = "nix search --inputs-from $HOME/.nix-out/vix nixpkgs $argv";
          };

          # Ripgrep helpers for nix directories
          rg-vix = {
            description = "Search on current vix";
            body = "rg $argv $HOME/.nix-out/vix";
          };
          rg-nixpkgs = {
            description = "Search on current nixpkgs";
            body = "rg $argv $HOME/.nix-out/nixpkgs";
          };
          rg-home-manager = {
            description = "Search on current home-manager";
            body = "rg $argv $HOME/.nix-out/home-manager";
          };
          rg-nix-darwin = {
            description = "Search on current nix-darwin";
            body = "rg $argv $HOME/.nix-out/nix-darwin";
          };

          # NixOS search helpers
          nixos-opt = {
            description = "Open a browser on search.nixos.org for options";
            body = ''open "https://search.nixos.org/options?sort=relevance&query=$argv"'';
          };
          nixos-pkg = {
            description = "Open a browser on search.nixos.org for packages";
            body = ''open "https://search.nixos.org/packages?sort=relevance&query=$argv"'';
          };
          repology-nixpkgs = {
            description = "Open a browser on search for nixpkgs on repology.org";
            body = ''open "https://repology.org/projects/?inrepo=nix_unstable&search=$argv"'';
          };

          # Rust development
          cwe = {
            description = "Cargo watch and run example";
            body = ''cargo watch -q -c -x "run -q --example $argv[1]"'';
          };
          cw = {
            description = "Cargo watch and run (main.rs or lib.rs)";
            body = ''cargo watch -q -c -x "run -q"'';
          };

          # TV completion widget
          __tv_complete = {
            description = "fish completion widget with tv";
            body = ''
              # modified from https://github.com/junegunn/fzf/wiki/Examples-(fish)#completion
              set -l cmd (commandline -co) (commandline -ct)

              switch $cmd[1]
                  case env sudo
                      for i in (seq 2 (count $cmd))
                          switch $cmd[$i]
                              case '-*'
                              case '*=*'
                              case '*'
                                  set cmd $cmd[$i..-1]
                                  break
                          end
                      end
              end

              set -l cmd_lastw $cmd[-1]
              set cmd (string join -- ' ' $cmd)

              set -l complist (complete -C$cmd)
              set -l result

              # do nothing if there is nothing to select from
              test -z "$complist"; and return

              set -l compwc (echo $complist | wc -w)
              if test $compwc -eq 1
                  # if there is only one option dont open fzf
                  set result "$complist"
              else
                  set result (string join -- \n $complist | column -t -l 2 -o \t |  tv --select-1 --no-status-bar --keybindings='tab="confirm_selection"' --inline  --input-header "$cmd" | string split -m 2 -f 1 \t | string trim --right)
              end

              set -l prefix (string sub -s 1 -l 1 -- (commandline -t))
              for i in (seq (count $result))
                  set -l r $result[$i]
                  switch $prefix
                      case "'"
                          commandline -t -- (string escape -- $r)
                      case '"'
                          if string match '*"*' -- $r >/dev/null
                              commandline -t -- (string escape -- $r)
                          else
                              commandline -t -- '"'$r'"'
                          end
                      case '~'
                          commandline -t -- (string sub -s 2 (string escape -n -- $r))
                      case '*'
                          commandline -t -- $r
                  end
                  commandline -i ' '
              end
              commandline -f repaint
            '';
          };
        };

        interactiveShellInit = ''
          # Unbind Ctrl+l (default clear binding) to allow it to pass through to Zellij
          bind -e \cl

          # Bind Tab to tv completion widget
          bind \t __tv_complete

          # Add bun global bin to PATH
          fish_add_path ~/.bun/bin
        '';
      };
    };
  };
}
