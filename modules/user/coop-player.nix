{ fleet, __findFile, ... }:
{
  # Shape shared by the local co-op gaming accounts (bri, carter): launched
  # from the admin's graphical session via ego / controller-split, so they
  # need the session device groups but never wheel or root-equivalent groups.
  fleet.user._.coop-player = {
    description = "Local co-op gaming account — bash login, session device groups, Proton tooling, basic apps";

    includes = [
      (<den/user-shell> "bash")
      # Proton tooling (protonup-rs, protontricks, dotnet 6) in the user's
      # home. System-wide GE-Proton comes from <fleet.gaming/steam> at the host.
      <fleet.gaming/proton>
      (<fleet.user/groups> [
        "networkmanager"
        "audio"
        "video"
        "render"
        "input"
        "gamemode"
        "pipewire"
      ])
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          firefox
          vim
          htop
          git
        ];
      };
  };
}
