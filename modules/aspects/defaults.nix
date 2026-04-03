{ __findFile, den, ... }:
{
  den.default = {
    includes = [
      <den/define-user>
      den.aspects.hm
      den.aspects.hm-host-forward
      den._.inputs'
      den._.self'
      <FTS/base-host>
      <FTS/nix-settings>
      <FTS/state-version>
      <FTS/hostname>
      <FTS/no-man-cache>
    ];
    home.includes = [
      <FTS/nix>
      <FTS/user-secrets>
    ];
  };
}
