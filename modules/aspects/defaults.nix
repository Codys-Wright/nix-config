{ __findFile, den, ... }:
{
  den.default = {
    includes = [
      <den/define-user>
      den.aspects.hm
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

  # Enable mutual-provider: host aspects with homeManager blocks automatically
  # contribute to users, and user aspects with nixos blocks contribute to hosts.
  # Replaces the custom hm-host-forward workaround.
  den.ctx.user.includes = [ den._.mutual-provider ];
}
