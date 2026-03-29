# MicroVM configuration for THEBATTLESHIP — graphical niri desktop for local testing
# Run with: nix run .#THEBATTLESHIP-vm
# Opens a GTK window with niri auto-launched as cody (password: cody)
# SSH also available: ssh -p 2222 root@localhost
{
  inputs,
  FTS,
  __findFile,
  ...
}:
{
  den.hosts.x86_64-linux.THEBATTLESHIP-vm = {
    description = "THEBATTLESHIP MicroVM — graphical niri desktop for local testing";
    aspect = "THEBATTLESHIP-vm";
    # No den users — home-manager for cody is wired directly below to avoid SOPS
  };

  den.aspects.THEBATTLESHIP-vm = {
    description = "MicroVM with niri desktop for testing THEBATTLESHIP config";
    includes = [
      <FTS.desktop/environment/niri>
      <FTS.coding/cli>
      <FTS.coding/editors>
      <FTS.coding/shells>
    ];

    nixos =
      { pkgs, ... }:
      {
        imports = [
          inputs.microvm.nixosModules.microvm
          inputs.home-manager.nixosModules.home-manager
        ];

        microvm = {
          hypervisor = "qemu";
          mem = 4096;
          vcpu = 4;
          shares = [
            {
              proto = "9p";
              tag = "ro-store";
              source = "/nix/store";
              mountPoint = "/nix/.ro-store";
            }
          ];
          interfaces = [
            {
              type = "user";
              id = "vm-eth0";
              mac = "02:00:00:00:00:01";
            }
          ];
          forwardPorts = [
            {
              from = "host";
              host.port = 2222;
              guest.port = 22;
            }
          ];
          # Enable GTK display window — microvm uses full qemu (not qemu-for-vm-tests) when this is set
          graphics.enable = true;
        };

        networking.hostName = "THEBATTLESHIP-vm";
        time.timeZone = "America/Los_Angeles";

        # cody user — simple password, no SOPS (VM-only, not through den pipeline)
        users.users.cody = {
          isNormalUser = true;
          initialPassword = "cody";
          uid = 1000;
          extraGroups = [
            "wheel"
            "video"
            "input"
            "audio"
          ];
        };

        # Auto-login cody directly into niri on boot
        services.greetd = {
          enable = true;
          settings.default_session = {
            command = "${pkgs.niri}/bin/niri-session";
            user = "cody";
          };
        };

        # SSH root access for debugging
        users.users.root.initialPassword = "root";
        services.openssh = {
          enable = true;
          settings = {
            PermitRootLogin = "yes";
            PasswordAuthentication = true;
          };
        };
        networking.firewall.allowedTCPPorts = [ 22 ];

        # Configure niri for cody directly via home-manager (bypasses den pipeline → no SOPS)
        # Settings mirror the FTS.desktop.environment.niri homeManager block
        home-manager.users.cody =
          { pkgs, ... }:
          {
            programs.niri.settings = {
              input = {
                keyboard = {
                  xkb = {
                    layout = "us";
                    options = "caps:escape";
                  };
                  repeat-rate = 40;
                  repeat-delay = 250;
                };
                touchpad = {
                  tap = true;
                  natural-scroll = true;
                };
                mouse.accel-profile = "flat";
              };
              layout = {
                gaps = 5;
                center-focused-column = "never";
                default-column-width.proportion = 0.5;
                focus-ring = {
                  width = 2;
                  active.color = "#89b4fa";
                  inactive.color = "#313244";
                };
                border.enable = false;
              };
              animations.enable = true;
              prefer-no-csd = true;
              workspaces = {
                w0 = { };
                w1 = { };
                w2 = { };
                w3 = { };
                w4 = { };
                w5 = { };
                w6 = { };
                w7 = { };
                w8 = { };
                w9 = { };
              };
              environment = {
                DISPLAY = ":0";
                NIXOS_OZONE_WL = "1";
                MOZ_ENABLE_WAYLAND = "1";
              };
              spawn-at-startup = [
                { command = [ "xwayland-satellite" ]; }
                { command = [ "mako" ]; }
                { command = [ "waybar" ]; }
              ];
              binds =
                let
                  mod = "Super";
                  grim = "${pkgs.grim}/bin/grim";
                  slurp = "${pkgs.slurp}/bin/slurp";
                  swappy = "${pkgs.swappy}/bin/swappy";
                  wlCopy = "${pkgs.wl-clipboard}/bin/wl-copy";
                  wlPaste = "${pkgs.wl-clipboard}/bin/wl-paste";
                in
                {
                  "${mod}+Return".action.spawn = "kitty";
                  "${mod}+D".action.spawn = "fuzzel";
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
                  "XF86AudioRaiseVolume".action.spawn-sh = "wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+";
                  "XF86AudioLowerVolume".action.spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
                  "XF86AudioMute".action.spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
                  "Print".action.screenshot = { };
                  "${mod}+Ctrl+S".action.spawn-sh = "${grim} -l 0 - | ${wlCopy}";
                  "${mod}+Shift+S".action.spawn-sh = "${grim} -g \"$(${slurp} -w 0)\" - | ${wlCopy}";
                  "${mod}+Shift+E".action.spawn-sh = "${wlPaste} | ${swappy} -f -";
                  "${mod}+Alt+L".action.spawn = "swaylock";
                  "${mod}+Shift+Q".action.quit = { };
                };
            };

            home.stateVersion = "25.11";
          };
      };
  };
}
