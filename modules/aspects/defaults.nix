{ __findFile, den, ... }:
{
  den.default = {
    includes = [
      <den/define-user>
      den.aspects.hm
      den._.inputs'
      den._.self'
      <fleet/base-host>
      <fleet/nix-settings>
      <fleet/state-version>
      <fleet/no-man-cache>
      den._.hostname
    ];
    home.includes = [
      <fleet/nix>
      <fleet/user-secrets>
    ];
  };

  # Enable mutual-provider: host aspects with homeManager blocks automatically
  # contribute to users, and user aspects with nixos blocks contribute to hosts.
  # Replaces the custom hm-host-forward workaround.
  den.ctx.user.includes = [ den._.mutual-provider ];
}
