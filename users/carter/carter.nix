{ __findFile, ... }:
{
  den.homes.x86_64-linux.carter = {
    userName = "carter";
  };

  den.aspects.carter = {
    description = "Carter user — local co-op gaming account, launched from Cody's session via ego";

    includes = [
      <fleet.user/coop-player>
      (<fleet.user/password> {
        method = "hashed";
        value = "$6$fncYrVMO/9rhDTcj$bL6xaLsi3pv2c4N8FPFjEM8FoHsbL8ZORPq9cyKI8CWrS/UzknCsslUICzCvtAVv3cgQ3MDiDsEsammxQNxOj1";
      })
    ];

    user.description = "Carter";
  };
}
