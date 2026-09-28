# Gaming platforms aggregator
# Usage: <fleet/gaming>
{
  fleet,
  __findFile,
  ...
}:
{
  fleet.gaming = {
    description = "All gaming platforms and tools";

    # Host side: the system halves (steam, sunshine, proton's env var, …).
    # Home-manager-only leaves are harmless here — host scope drops them.
    includes = [
      <fleet.gaming/steam>
      <fleet.gaming/minecraft>
      <fleet.gaming/lutris>
      <fleet.gaming/bottles>
      <fleet.gaming/winboat>
      <fleet.gaming/proton>
      <fleet.gaming/melonloader>
      <fleet.gaming/r2modman>
      <fleet.gaming/sunshine>
    ];

    # User side: host scope never delivers homeManager, so the per-user
    # half reaches the host's users through this explicit edge. Accounts
    # that shouldn't get it carry <fleet.user/restricted>.
    provides.to-users.includes = [
      (<fleet.user/unless-restricted> <fleet.gaming/player>)
    ];
  };

  fleet.gaming._.player = {
    description = "Per-user gaming half: launchers, mod managers and Proton tooling";
    includes = [
      <fleet.gaming/minecraft>
      <fleet.gaming/lutris>
      <fleet.gaming/bottles>
      <fleet.gaming/winboat>
      <fleet.gaming/proton>
      <fleet.gaming/melonloader>
      <fleet.gaming/r2modman>
    ];
  };
}
