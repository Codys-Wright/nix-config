# Hermes "bot screen" on this host for the `agent` user. When a starcommand
# Hermes profile runs here over SSH (terminal.backend ssh), Hermes starts a
# private headless desktop on this machine for it: TigerVNC's Xvnc plus the
# Xfce parts started one by one (tools/bot_desktop/launcher.sh upstream), with
# Chromium, agent-browser and cua-driver, streamed into Hermes Desktop's
# Screen pane. It never touches the desktop of the person at this machine.
#
# All of it has to resolve from a non-interactive SSH login, so the binaries go
# on the agent user's profile and the Playwright browser path is a PAM session
# variable (an ssh session never sees shell-rc exports).
{ inputs, ... }:
{
  fleet.system._.agent-bot-desktop = {
    description = "Hermes bot screen for the agent user (Xvnc + Xfce, Chromium, agent-browser, cua-driver)";

    nixos =
      { pkgs, ... }:
      let
        hermes = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system};
        # Hermes's own pinned driver ships a bare executable at its root.
        cuaDriver = pkgs.runCommand "cua-driver-bin" { } ''
          mkdir -p $out/bin
          ln -s ${hermes.pm-cua-driver}/cua-driver $out/bin/cua-driver
        '';
        # Hermes and agent-browser look for Playwright's layout:
        # $PLAYWRIGHT_BROWSERS_PATH/chromium-*/chrome-linux64/chrome.
        playwrightBrowsers = pkgs.linkFarm "hermes-playwright-browsers" [
          {
            name = "chromium-${hermes.pm-chromium.version or "pinned"}";
            path = hermes.pm-chromium;
          }
        ];
      in
      {
        users.users.agent.packages = [
          pkgs.tigervnc
          pkgs.xfwm4
          pkgs.xfdesktop
          pkgs.xfce4-panel
          pkgs.xfce4-settings
          pkgs.dbus
          pkgs.xauth
          pkgs.xdpyinfo
          pkgs.xsetroot
          pkgs.xset
          pkgs.xprop
          pkgs.setxkbmap
          pkgs.xkbcomp
          pkgs.xkeyboard-config
          pkgs.xfce4-terminal
          pkgs.agent-browser
          cuaDriver
        ];
        environment.sessionVariables.PLAYWRIGHT_BROWSERS_PATH = "${playwrightBrowsers}";
      };
  };
}
