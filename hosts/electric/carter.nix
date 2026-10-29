# Carter on electric: his own machine, so the primary account (not the co-op
# shape he has on THEBATTLESHIP). Included from den.aspects.carter when the
# host is electric (users/carter/carter.nix).
{ fleet, __findFile, ... }:
{
  den.aspects.carter-electric = {
    description = "Carter's account on electric: primary user, his apps, music, gaming";

    includes = [
      <den/primary-user>

      <fleet/coding>
      (<fleet.user/shell> "nushell")
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

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          mari0
          qjackctl
          p7zip-rar
          carla
          raysession
          davinci-resolve
          dexed
        ];
      };

    homeManager = {
      programs.ssh.enable = true;
    };
  };
}
