{
  den.aspects.hm-backup = {
    description = "Renames conflicting home-manager backup files with a timestamp suffix";
    os =
      { pkgs, ... }:
      let
        hm-backup = pkgs.writeShellScript "hm-backup" ''
          mv -- "$1" "$1.hm-backup-$(date +%Y%m%d%H%M%S)"
        '';
      in
      {
        home-manager.backupCommand = "${hm-backup}";
      };
  };
}
