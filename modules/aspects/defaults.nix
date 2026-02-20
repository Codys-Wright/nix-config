{ __findFile, den, ... }:
{
  den.default.includes = [
    <den/define-user>
    den.aspects.hm
    den._.inputs'
    den._.self'
    <FTS/base-host>
    <FTS/base-home>
    <FTS/nix-settings>
    <FTS/state-version>
    <FTS/hostname>
  ];
}
