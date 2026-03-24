{
  den.aspects.hm-backup = {
    nixos = { pkgs, ... }:
      let
        hm-backup = pkgs.writeShellScript "hm-backup" ''
          mv -- "$1" "$1.hm-backup-$(date +%Y%m%d%H%M%S)"
        '';
      in
      {
        home-manager.backupCommand = "${hm-backup}";
      };
    darwin = { pkgs, ... }:
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
