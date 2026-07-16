{
  fleet.state-version = {
    description = "Pins nixos/home-manager/darwin state versions fleet-wide";
    nixos.system.stateVersion = "25.11";
    homeManager.home.stateVersion = "25.11";
    darwin.system.stateVersion = 6;
  };
}
