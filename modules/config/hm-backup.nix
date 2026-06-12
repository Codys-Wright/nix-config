{ inputs, ... }:
{
  den.aspects.hm-backup = {
    description = "Sets a per-flake-revision backup extension so repeated home-manager activations don't clobber prior backups";
    os = _: {
      home-manager.backupFileExtension = "bak-${toString inputs.self.lastModified}";
    };
  };
}
