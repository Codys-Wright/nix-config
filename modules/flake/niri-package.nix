# Standalone niri package with the full desktop config embedded.
# Run with: nix run .#niri
#
# Extracts the homeManager module from FTS.desktop.environment.niri,
# evaluates it with home-manager standalone (overriding mod=Alt so it
# doesn't conflict with the host compositor), and wraps the niri binary
# with the validated config.kdl and all needed tools bundled in PATH.
#
# This lets you test the niri config without a VM — just run `nix run .#niri`
# and niri opens as a nested window inside your existing compositor.
{
  inputs,
  FTS,
  lib,
  ...
}:
{
  perSystem =
    { pkgs, system, ... }:
    lib.optionalAttrs (system == "x86_64-linux") {
      packages.niri =
        let
          # Tools required by the niri session (spawn-at-startup + keybinds)
          sessionTools = with pkgs; [
            xwayland-satellite
            noctalia-shell
            wlr-which-key
            swaybg
            swaylock
            swayidle
            wl-clipboard
            grim
            slurp
            swappy
            kitty
          ];

          # Pull the homeManager block directly from the niri aspect.
          niriHmModule = FTS.desktop._.environment._.niri.homeManager;

          # Override: use Alt as mod key so nested niri doesn't conflict
          # with the host compositor's Super bindings.
          nestedOverride =
            { lib, pkgs, ... }:
            let
              mod = "Alt";
              grim = "${pkgs.grim}/bin/grim";
              slurp = "${pkgs.slurp}/bin/slurp";
              swappy = "${pkgs.swappy}/bin/swappy";
              wlCopy = "${pkgs.wl-clipboard}/bin/wl-copy";
              wlPaste = "${pkgs.wl-clipboard}/bin/wl-paste";
            in
            {
              programs.niri.settings.binds = lib.mkForce {
                "${mod}+Return".action.spawn = "kitty";
                "${mod}+D".action.spawn-sh = "noctalia-shell ipc call launcher toggle";
                "${mod}+Space".action.spawn = "wlr-which-key";
                "${mod}+Q".action.close-window = { };
                "${mod}+F".action.maximize-column = { };
                "${mod}+G".action.fullscreen-window = { };
                "${mod}+Shift+F".action.toggle-window-floating = { };
                "${mod}+C".action.center-column = { };
                "${mod}+H".action.focus-column-left = { };
                "${mod}+L".action.focus-column-right = { };
                "${mod}+K".action.focus-window-up = { };
                "${mod}+J".action.focus-window-down = { };
                "${mod}+Left".action.focus-column-left = { };
                "${mod}+Right".action.focus-column-right = { };
                "${mod}+Up".action.focus-window-up = { };
                "${mod}+Down".action.focus-window-down = { };
                "${mod}+Shift+H".action.move-column-left = { };
                "${mod}+Shift+L".action.move-column-right = { };
                "${mod}+Shift+K".action.move-window-up = { };
                "${mod}+Shift+J".action.move-window-down = { };
                "${mod}+Ctrl+H".action.set-column-width = "-5%";
                "${mod}+Ctrl+L".action.set-column-width = "+5%";
                "${mod}+Ctrl+J".action.set-window-height = "-5%";
                "${mod}+Ctrl+K".action.set-window-height = "+5%";
                "${mod}+1".action.focus-workspace = "w0";
                "${mod}+2".action.focus-workspace = "w1";
                "${mod}+3".action.focus-workspace = "w2";
                "${mod}+4".action.focus-workspace = "w3";
                "${mod}+5".action.focus-workspace = "w4";
                "${mod}+6".action.focus-workspace = "w5";
                "${mod}+7".action.focus-workspace = "w6";
                "${mod}+8".action.focus-workspace = "w7";
                "${mod}+9".action.focus-workspace = "w8";
                "${mod}+0".action.focus-workspace = "w9";
                "${mod}+Shift+1".action.move-column-to-workspace = "w0";
                "${mod}+Shift+2".action.move-column-to-workspace = "w1";
                "${mod}+Shift+3".action.move-column-to-workspace = "w2";
                "${mod}+Shift+4".action.move-column-to-workspace = "w3";
                "${mod}+Shift+5".action.move-column-to-workspace = "w4";
                "${mod}+Shift+6".action.move-column-to-workspace = "w5";
                "${mod}+Shift+7".action.move-column-to-workspace = "w6";
                "${mod}+Shift+8".action.move-column-to-workspace = "w7";
                "${mod}+Shift+9".action.move-column-to-workspace = "w8";
                "${mod}+Shift+0".action.move-column-to-workspace = "w9";
                "${mod}+WheelScrollDown".action.focus-column-right = { };
                "${mod}+WheelScrollUp".action.focus-column-left = { };
                "${mod}+Ctrl+WheelScrollDown".action.focus-workspace-down = { };
                "${mod}+Ctrl+WheelScrollUp".action.focus-workspace-up = { };
                "Print".action.screenshot = { };
                "${mod}+Ctrl+S".action.spawn-sh = "${grim} -l 0 - | ${wlCopy}";
                "${mod}+Shift+S".action.spawn-sh = "${grim} -g \"$(${slurp} -w 0)\" - | ${wlCopy}";
                "${mod}+Shift+E".action.spawn-sh = "${wlPaste} | ${swappy} -f -";
                # No swaylock bind in nested mode (Alt+Alt+L would conflict with Alt+L)
                "${mod}+Shift+Q".action.quit = { };
              };
            };

          # Evaluate home-manager standalone with the niri aspect + nested override.
          hmConfig = inputs.home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              niriHmModule
              nestedOverride
              {
                home.username = "user";
                home.homeDirectory = "/home/user";
                home.stateVersion = "25.11";
              }
            ];
          };

          # niri-flake writes the validated config.kdl to xdg.configFile."niri-config"
          configKdl = hmConfig.config.xdg.configFile."niri-config".source;

          # Use niri-stable from the niri-flake input (same version as the system config)
          niriPkg = inputs.niri-flake.packages.${system}.niri-stable;

          toolsPath = lib.makeBinPath sessionTools;
        in
        pkgs.writeShellScriptBin "niri" ''
          export PATH="${toolsPath}:$PATH"
          exec ${niriPkg}/bin/niri -c ${configKdl} "$@"
        '';
    };
}
