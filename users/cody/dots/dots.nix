{
  # Use hjem instead of mkOutOfStoreSymlink !
  cody.dots = {
    homeManager =
      { config, pkgs, ... }:
      let
        dotsLink =
          path:
          config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.flake/users/cody/dots/${path}";
      in
      {
        home.activation.link-flake = config.lib.dag.entryAfter [ "writeBoundary" ] ''
          echo Checking that "$HOME/.flake" exists.
          if ! test -L "$HOME/.flake"; then
            echo "Creating $HOME/.flake symlink..."
            # Try to find the flake root by looking for flake.nix
            FLAKE_ROOT=""
            # Check common locations
            if test -f "$HOME/nix-config/flake.nix"; then
              FLAKE_ROOT="$HOME/nix-config"
            elif test -f "$HOME/Documents/Development/nix-test/nix-config/flake.nix"; then
              FLAKE_ROOT="$HOME/Documents/Development/nix-test/nix-config"
            elif test -f "/etc/nixos/flake.nix"; then
              FLAKE_ROOT="/etc/nixos"
            else
              # Try to find flake.nix by walking up from current directory
              CURRENT_DIR="$PWD"
              while [ "$CURRENT_DIR" != "/" ]; do
                if test -f "$CURRENT_DIR/flake.nix"; then
                  FLAKE_ROOT="$CURRENT_DIR"
                  break
                fi
                CURRENT_DIR="$(dirname "$CURRENT_DIR")"
              done
            fi
            
            if [ -n "$FLAKE_ROOT" ] && [ -f "$FLAKE_ROOT/flake.nix" ]; then
              echo "Found flake at $FLAKE_ROOT, creating symlink..."
              ln -sfn "$FLAKE_ROOT" "$HOME/.flake"
            else
              echo "Warning: Could not find flake.nix. Please create $HOME/.flake manually pointing to your flake root."
              echo "You can create it with: ln -sfn /path/to/your/flake $HOME/.flake"
            fi
          else
            echo "$HOME/.flake link already exists."
          fi
        '';

        home.file.".ssh" = {
          recursive = true;
          source = ./ssh;
        };

        home.file.".config/niri".source = dotsLink "config/niri";
        # home.file.".config/nvim".source = dotsLink "config/nvim";
        home.file.".config/astrovim".source = dotsLink "config/astrovim";
        
        home.file.".config/vscode-vim".source = dotsLink "config/vscode-vim";
        home.file.".config/doom".source = dotsLink "config/doom";
        home.file.".config/zed".source = dotsLink "config/zed";
        home.file.".config/wezterm".source = dotsLink "config/wezterm";
        home.file.".config/ghostty".source = dotsLink "config/ghostty";

        home.file.".config/Code/User/settings.json".source = dotsLink "config/Code/User/settings.json";
        home.file.".config/Code/User/keybindings.json".source =
          dotsLink "config/Code/User/keybindings.json";
        home.file.".vscode/extensions/extensions.json".source =
          dotsLink "vscode/extensions/extensions-${pkgs.stdenv.hostPlatform.uname.system}.json";

        home.file.".config/Cursor/User/settings.json".source = dotsLink "config/Code/User/settings.json";
        home.file.".config/Cursor/User/keybindings.json".source =
          dotsLink "config/Code/User/keybindings.json";
        home.file.".cursor/extensions/extensions.json".source =
          dotsLink "cursor/extensions/extensions-${pkgs.stdenv.hostPlatform.uname.system}.json";

      };
  };
}
