{ inputs, fleet, ... }:
{
  fleet.hm-backup = {
    description = "Sets a per-flake-revision backup extension so repeated home-manager activations don't clobber prior backups";
    os.home-manager.backupFileExtension = "bak-${toString inputs.self.lastModified}";
  };

  # Every host that embeds home-manager (den's hm-host kind); hosts without
  # HM users (beacon, airlock) have no home-manager option to set.
  den.schema.hm-host.includes = [ fleet.hm-backup ];
}
