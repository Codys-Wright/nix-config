# Herdr desktop app (herdrdev/herdr-app) with its matching herdr-core, from
# numtide's llm-agents.nix. herdr-nix only packages the terminal CLI (see
# modules/coding/cli/herdr.nix); nixpkgs' herdr-desktop lags the releases.
#
# No nixpkgs follows: llm-agents' cache (cache.numtide.com, in
# modules/config/nix-settings.nix) only hits on its own nixpkgs revision,
# and building the app pulls in Rust, Zig and Ghostty.
{ inputs, lib, ... }:
{
  flake-file.inputs.llm-agents.url = lib.mkDefault "github:numtide/llm-agents.nix";

  fleet.apps._.misc._.herdr-app = {
    description = "Herdr desktop app (terminals and coding agents that keep running) + herdr-core";

    homeManager =
      { pkgs, lib, ... }:
      let
        llm = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
      in
      {
        home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          llm.herdr-app
          llm.herdr-core
        ];
      };
  };
}
