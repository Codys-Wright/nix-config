{ __findFile, den, ... }:
{
  den.default = {
    includes = [
      <den/home-manager>
      <den/define-user>
      den.aspects.hm
      den._.inputs'
      den._.self'
      <FTS/base-host>
      <FTS/nix-settings>
      <FTS/state-version>
      <FTS/hostname>
    ];
    home.includes = [
      <FTS/nix>
      <FTS/user-secrets>
    ];
  };
}
