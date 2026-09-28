{ __findFile, ... }:
{
  den.homes.x86_64-linux.bri = {
    userName = "bri";
  };

  den.aspects.bri = {
    description = "Bri user — local co-op gaming account, launched from Cody's session via ego";

    includes = [
      <fleet.user/coop-player>
      (<fleet.user/password> {
        method = "hashed";
        value = "$6$.E5U9uf5rBti35ez$7x.Rmf/Sfu7tN6g0qMEShgRhi3rxF62P4bJHvqQkJcrRF/fSlwkK6mxtWrM1XAFfref6BIkFrUmnrKr5CzyiJ1";
      })
    ];

    user.description = "Bri";
  };
}
