{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.config.user;
  defaultIconFileName = "profile.png";
  defaultIcon = pkgs.stdenvNoCC.mkDerivation {
    name = "default-icon";
    src = ./. + "/${defaultIconFileName}";

    dontUnpack = true;

    installPhase = ''
      cp $src $out
    '';

    passthru = {
      fileName = defaultIconFileName;
    };
  };
  propagatedIcon =
    pkgs.runCommandNoCC "propagated-icon"
      {
        passthru = {
          fileName = cfg.icon.fileName;
        };
      }
      ''
        local target="$out/share/zeus-icons/user/${cfg.name}"
        mkdir -p "$target"

        cp ${cfg.icon} "$target/${cfg.icon.fileName}"
      '';
in
{
  options.${namespace}.config.user = with types; {
    name = mkOpt str "ryan" "The name to use for the user account.";
    fullName = mkOpt str "Ryan Wüest" "The full name of the user.";
    email = mkOpt str "ryan.wueest@protonmail.com" "The email of the user.";
    initialPassword =
      mkOpt str "password"
        "The initial password to use when the user is first created.";
    icon = mkOpt (nullOr package) defaultIcon "The profile picture to use for the user.";
    prompt-init = mkBoolOpt true "Whether or not to show an initial message when opening a new shell.";
    extraGroups = mkOpt (listOf str) [ ] "Groups for the user to be assigned.";
    extraOptions = mkOpt attrs { } (mdDoc "Extra options passed to `users.users.<name>`.");
  };

  config = {
    environment.systemPackages = with pkgs; [ propagatedIcon ];

    programs.zsh = enabled;

    users.users.${cfg.name} = {
      isNormalUser = true;

      inherit (cfg) name initialPassword;

      home = "/home/${cfg.name}";
      group = "users";

      shell = pkgs.zsh;

      # Let NixOS assign UID automatically to avoid conflicts
      # uid = 1000;

      extraGroups = cfg.extraGroups;
    };
  };
}
