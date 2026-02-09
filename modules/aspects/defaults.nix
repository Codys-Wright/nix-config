{ __findFile, ... }:
{
  den.default.includes = [
    <den/define-user>
    <FTS/base-host>
    <FTS/base-home>
    <FTS/nix-settings>
    <FTS/state-version>
    <FTS/hostname>
  ];
}
