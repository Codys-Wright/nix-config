# Odysseus — self-hosted AI workspace. The server runs in the Starcommand
# cluster (~/.starcommand modules/services/odysseus, pinned to THEBATTLESHIP,
# http://127.0.0.1:7000); this is the desktop side: an "Odysseus" launcher that
# opens it in its own app window, like ComfyUI's.
{ lib, ... }:
{
  fleet.apps._.odysseus = {
    description = "Odysseus app launcher (opens the Starcommand-hosted Odysseus on :7000 in its own window)";

    provides.to-users.homeManager =
      { pkgs, ... }:
      let
        open = pkgs.writeShellScript "odysseus-app" ''
          exec ${lib.getExe pkgs.brave} --app=http://127.0.0.1:7000 \
            --user-data-dir="$HOME/.local/share/odysseus-app" "$@"
        '';
      in
      {
        xdg.dataFile."icons/hicolor/scalable/apps/odysseus.svg".source = ./_odysseus.svg;
        xdg.desktopEntries.odysseus = {
          name = "Odysseus";
          genericName = "AI Workspace";
          comment = "Self-hosted AI workspace: chat, agents, research, documents";
          exec = "${open}";
          icon = "odysseus";
          categories = [
            "Development"
            "Office"
          ];
        };
      };
  };
}
