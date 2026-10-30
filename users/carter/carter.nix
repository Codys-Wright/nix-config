{
  den,
  __findFile,
  ...
}:
let
  onElectric =
    {
      host ? null,
      ...
    }:
    host != null && host.hasAspect den.aspects.electric;
in
{
  den.homes.x86_64-linux.carter = {
    userName = "carter";
  };

  den.aspects.carter = {
    description = "Carter user — his own machine (electric), co-op gaming account elsewhere";

    includes = [
      # electric is Carter's desktop: primary account (hosts/electric/carter.nix).
      (den.lib.policy.when onElectric { includes = [ den.aspects.carter-electric ]; })

      # Everywhere else: local co-op account, launched from Cody's session via ego.
      (den.lib.policy.when (args: !(onElectric args)) {
        includes = [
          <fleet.user/coop-player>
          (<fleet.user/password> {
            method = "hashed";
            value = "$6$fncYrVMO/9rhDTcj$bL6xaLsi3pv2c4N8FPFjEM8FoHsbL8ZORPq9cyKI8CWrS/UzknCsslUICzCvtAVv3cgQ3MDiDsEsammxQNxOj1";
          })
        ];
      })
    ];

    user.description = "Carter";
  };
}
