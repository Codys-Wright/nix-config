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
      { pkgs, lib, ... }:
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
          # Open a GTK window with GPU acceleration
          qemu.extraArgs = [
            "-device"
            "virtio-vga-gl"
            "-display"
            "gtk,gl=on"
            "-device"
            "virtio-keyboard-pci"
            "-device"
            "virtio-mouse-pci"
          ];
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
        home-manager.users.cody =
          { ... }:
          {
            programs.niri = {
              enable = true;
              settings = {
                input.keyboard.xkb.layout = "us";
                input.touchpad = {
                  tap = true;
                  natural-scroll = true;
                };
                layout = {
                  gaps = 8;
                  center-focused-column = "never";
                  default-column-width.proportion = 0.5;
                  border = {
                    width = 2;
                    active.color = "#89b4fa";
                    inactive.color = "#313244";
                  };
                };
                animations.enable = true;
                prefer-no-csd = true;
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
                  in
                  {
                    "${mod}+Return".action.spawn = "kitty";
                    "${mod}+D".action.spawn = "fuzzel";
                    "${mod}+Q".action.close-window = { };
                    "${mod}+H".action.focus-column-left = { };
                    "${mod}+L".action.focus-column-right = { };
                    "${mod}+J".action.focus-window-down = { };
                    "${mod}+K".action.focus-window-up = { };
                    "${mod}+Shift+H".action.move-column-left = { };
                    "${mod}+Shift+L".action.move-column-right = { };
                    "${mod}+Shift+J".action.move-window-down = { };
                    "${mod}+Shift+K".action.move-window-up = { };
                    "${mod}+1".action.focus-workspace = 1;
                    "${mod}+2".action.focus-workspace = 2;
                    "${mod}+3".action.focus-workspace = 3;
                    "${mod}+4".action.focus-workspace = 4;
                    "${mod}+5".action.focus-workspace = 5;
                    "${mod}+Shift+1".action.move-column-to-workspace = 1;
                    "${mod}+Shift+2".action.move-column-to-workspace = 2;
                    "${mod}+Shift+3".action.move-column-to-workspace = 3;
                    "${mod}+Shift+4".action.move-column-to-workspace = 4;
                    "${mod}+Shift+5".action.move-column-to-workspace = 5;
                    "${mod}+F".action.fullscreen-window = { };
                    "${mod}+Minus".action.set-column-width = "-10%";
                    "${mod}+Equal".action.set-column-width = "+10%";
                    "Print".action.screenshot = { };
                    "${mod}+Shift+E".action.quit = { };
                  };
              };
            };

            home.stateVersion = "25.11";
          };
      };
  };
}
