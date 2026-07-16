{
  den,
  __findFile,
  ...
}:
{
  den.homes.x86_64-linux.joshua = {
    userName = "joshua";
  };

  den.aspects.joshua = {
    description = "Joshua user — browser-only child account";

    includes = [
      den.aspects.hm-backup
      <den/primary-user>

      # Browser only
      <fleet.apps/browsers/brave>
      (<fleet.apps/default-browser> "brave")

      (<fleet.user/password> {
        method = "hashed";
        value = "$6$Ws1Duox8/lqfT8ig$hVoe.bJu67HhMce9RGT6qycWSaLgPaITbLGB/jNn6uN5zp2Bgtbf.alg2zHmICmzjHjnW9ZIhXhD0.6dHscr7/";
      })

      # Split-out per-concern aspects (users/joshua/*.nix)
      den.aspects.joshua-account
      den.aspects.joshua-home-mount
      den.aspects.joshua-curfew
      den.aspects.joshua-brave-policies
    ];
  };
}
