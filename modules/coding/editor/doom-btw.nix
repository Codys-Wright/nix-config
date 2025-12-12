{ inputs, ... }:
{

  flake-file.inputs = {
    doom-emacs.flake = false;
    doom-emacs.url = "github:doomemacs/doomemacs";
    SPC.url = "github:vic/SPC";
  };

  FTS.coding._.editors._.doom-btw = {
    homeManager =
      { pkgs, lib, ... }:
      let
        emacsPkg = pkgs.emacs30;

        SPC = inputs.SPC.packages.${pkgs.stdenv.hostPlatform.system}.SPC.override { emacs = emacsPkg; };

      in
      {
        programs.emacs.enable = true;
        programs.emacs.package = lib.mkForce emacsPkg;
        #services.emacs.enable = true;
        services.emacs.package = lib.mkForce emacsPkg;
        services.emacs.extraOptions = [
          "--init-directory"
          "~/.config/emacs"
        ];

        home.packages = [
          SPC
          (pkgs.writeShellScriptBin "doom" ''exec $HOME/.config/emacs/bin/doom "$@"'')
          (pkgs.writeShellScriptBin "doomscript" ''exec $HOME/.config/emacs/bin/doomscript "$@"'')
          (pkgs.writeShellScriptBin "d" ''exec emacsclient -nw -a "doom run -nw --"  "$@"'')
        ];

        #home.activation.doom-install = lib.hm.dag.entryAfter [ "link-ssh-id" ] ''
        #  run ${lib.getExe doom-install}
        #'';
      };

  };

}
