# Coding parametric aspect
# Usage: (fleet.coding {
#   editors = [ "nvf" "cursor" "zed" ];
#   terminals = [ "ghostty" "kitty" "tmux" ];
#   shells = [ "fish" "zsh" ];
#   langs = [ "rust" "typescript" "python" ];
#   tools = [ "android" "dioxus" "podman" ];
# })
{
  lib,
  den,
  fleet,
  __findFile,
  ...
}:
{
  fleet.coding.description = "Development tools, languages, editors, terminals, and shells";

  fleet.coding.__functor =
    _self:
    {
      cli ? true,
      git ? true,
      lazygit ? true,
      devTools ? true,
      editors ? [ ],
      terminals ? [ ],
      shells ? [ ],
      langs ? [ ],
      tools ? [ ],
      ...
    }:
    let
      editorMap = {
        nvf = <fleet.coding._.editors/nvf>;
        cursor = <fleet.coding._.editors/cursor>;
        zed = <fleet.coding._.editors/zed>;
        neovim = <fleet.coding._.editors/neovim>;
      };

      terminalMap = {
        ghostty = <fleet.coding._.terminals/ghostty>;
        kitty = <fleet.coding._.terminals/kitty>;
        tmux = <fleet.coding._.terminals/tmux>;
        zellij = <fleet.coding._.terminals/zellij>;
        wezterm = <fleet.coding._.terminals/wezterm>;
      };

      shellMap = {
        fish = <fleet.coding._.shells/fish>;
        zsh = <fleet.coding._.shells/zsh>;
        nushell = <fleet.coding._.shells/nushell>;
        oh-my-posh = <fleet.coding._.shells/oh-my-posh>;
      };

      langMap = {
        rust = <fleet.coding._.lang/rust>;
        typescript = <fleet.coding._.lang/typescript>;
        python = <fleet.coding._.lang/python>;
      };

      toolMap = {
        android = <fleet.coding._.tools/android>;
        dioxus = <fleet.coding._.tools/dioxus>;
        "reverse-engineering" = <fleet.coding._.tools/reverse-engineering>;
        opencode = <fleet.coding._.tools/opencode>;
        "dev-tools" = <fleet.coding._.tools/dev-tools>;
        docker = <fleet.coding._.tools._.containers/docker>;
        podman = <fleet.coding._.tools._.containers/podman>;
      };
    in
    den.lib.parametric {
      includes =
        lib.optional cli <fleet.coding/cli>
        ++ lib.optional git <fleet.coding._.tools/git>
        ++ lib.optional lazygit <fleet.coding._.tools/lazygit>
        ++ lib.optional devTools <fleet.coding._.tools/dev-tools>
        ++ map (e: editorMap.${e}) editors
        ++ map (t: terminalMap.${t}) terminals
        ++ map (s: shellMap.${s}) shells
        ++ map (l: langMap.${l}) langs
        ++ map (t: toolMap.${t}) tools;
    };
}
