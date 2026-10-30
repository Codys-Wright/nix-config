# Carter on electric: his own machine, so the primary account (not the co-op
# shape he has on THEBATTLESHIP). Included from den.aspects.carter when the
# host is electric (users/carter/carter.nix).
{
  den,
  fleet,
  __findFile,
  ...
}:
{
  den.aspects.carter-electric = {
    description = "Carter's account on electric: primary user, his apps, music, gaming";

    includes = [
      <den/primary-user>
      den.aspects.carter-electric-unattended

      <fleet/coding>
      (<fleet.user/shell> "fish")
      (<fleet.coding/user-terminal> "ghostty")
      (fleet.git-identity {
        name = "electricsss";
        email = "electricsss@users.noreply.github.com";
      })

      <fleet/apps>
      <fleet.system/utils>
      <fleet.music._.production/producer>
      (<fleet.apps/default-browser> "brave")
      (<fleet.apps/default-file-manager> "nautilus")

      (<fleet.user/password> {
        method = "hashed";
        value = "$6$OUfl.yamDHnNiKEa$Q0.oJzvlBWb6d.p60tapv5.YqzQPrQx3eXcC5DrL5gCADyeAMBlHP4h.iyDkbc2E1V6W9hMNxROW4cRQi6UZt0";
      })
    ];

    # Not on electric: Android SDK / emulator images / Android Studio, and the
    # unfree GUI editors and API clients (none are on the public binary cache).
    excludes = [
      fleet.coding._.tools._.android
      fleet.coding._.editors._.cursor
      fleet.coding._.editors._.vscode
      fleet.coding._.tools._.api-clients
    ];

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          mari0
          qjackctl
          p7zip-rar
          carla
          raysession
          dexed
        ];
      };

    homeManager =
      { lib, ... }:
      {
        programs.ssh.enable = true;
        # No flake-input pins in carter's registry: each pin is a source tree
        # that has to be copied to electric (the global registry still
        # resolves `nixpkgs#…`).
        nix.registry = lib.mkForce { };

        # MiniMeters (carter's own XDG autostart entry) docks to the top edge as
        # a layer-shell surface; whichever surface maps first gets the edge, so
        # start it after Loft's bar is up to keep the bar on top.
        xdg.configFile."systemd/user/app-MiniMeters.AppImage@autostart.service.d/after-loft.conf".text = ''
          [Unit]
          After=loft-shell.service

          [Service]
          ExecStartPre=/run/current-system/sw/bin/sleep 3
        '';
      };
  };
}
