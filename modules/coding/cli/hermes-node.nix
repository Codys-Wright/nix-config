# A Mac that the starcommand Hermes can run sessions on: its per-machine
# profile (terminal.backend ssh) logs in here over SSH as `user`, so this turns
# on Remote Login, authorizes the starcommand agent key for that user, and puts
# what Hermes's ssh backend and tools expect on PATH. GNU tar comes first:
# Hermes unpacks files remotely with `tar --no-overwrite-dir`, a GNU option.
# Hermes Desktop (connects to the starcommand gateway) and cua-driver (computer
# use) come from the hermes-agent flake. THEBATTLESHIP (NixOS) uses
# fleet.system._.agent-user instead.
{
  inputs,
  ssh-keys,
  ...
}:
{
  fleet.coding._.cli._.hermes-node.__functor =
    _self:
    {
      # The macOS account Hermes logs in as (the one at the desktop, so
      # computer use reaches the real session).
      user,
      ...
    }:
    {
      name = "hermes-node(${user})";
      description = "Run starcommand Hermes sessions on this Mac over SSH as ${user} (Remote Login, agent key, tool kit, Hermes Desktop)";
      darwin =
        { pkgs, ... }:
        let
          hermes = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system};
        in
        {
          services.openssh.enable = true;
          users.users.${user}.openssh.authorizedKeys.keys = [ ssh-keys.fleet.starcommandAgent ];
          environment.systemPackages = [
            pkgs.gnutar
            pkgs.git
            pkgs.python3
            pkgs.nodejs
            pkgs.ripgrep
            pkgs.fd
            pkgs.jq
            pkgs.ffmpeg
            pkgs.gh
            pkgs.uv
            hermes.desktop
            hermes.pm-cua-driver
          ];
        };
    };
}
