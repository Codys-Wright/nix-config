{
  FTS,
  ...
}:
{
  FTS.state-version = {
    description = "Centralized default state versions";

    darwin.system.stateVersion = 6;
    nixos.system.stateVersion = "25.11";
    homeManager.home.stateVersion = "25.11";
  };
}
