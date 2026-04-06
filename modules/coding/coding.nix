# Coding parametric aspect
# Usage: (FTS.coding {
#   editors = [ "nvf" "cursor" "zed" ];
#   terminals = [ "ghostty" "kitty" "tmux" ];
#   shells = [ "fish" "zsh" ];
#   langs = [ "rust" "typescript" "python" ];
#   tools = [ "android" "dioxus" "podman" ];
# })
{
  lib,
  den,
  FTS,
  __findFile,
  ...
}:
{
  FTS.coding.description = "Development tools, languages, editors, terminals, and shells";

  FTS.coding.__functor =
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
        nvf = <FTS.coding._.editors/nvf>;
        cursor = <FTS.coding._.editors/cursor>;
        zed = <FTS.coding._.editors/zed>;
        neovim = <FTS.coding._.editors/neovim>;
      };

      terminalMap = {
        ghostty = <FTS.coding._.terminals/ghostty>;
        kitty = <FTS.coding._.terminals/kitty>;
        tmux = <FTS.coding._.terminals/tmux>;
        zellij = <FTS.coding._.terminals/zellij>;
        wezterm = <FTS.coding._.terminals/wezterm>;
      };

      shellMap = {
        fish = <FTS.coding._.shells/fish>;
        zsh = <FTS.coding._.shells/zsh>;
        nushell = <FTS.coding._.shells/nushell>;
        oh-my-posh = <FTS.coding._.shells/oh-my-posh>;
      };

      langMap = {
        rust = <FTS.coding._.lang/rust>;
        typescript = <FTS.coding._.lang/typescript>;
        python = <FTS.coding._.lang/python>;
      };

      toolMap = {
        android = <FTS.coding._.tools/android>;
        dioxus = <FTS.coding._.tools/dioxus>;
        "reverse-engineering" = <FTS.coding._.tools/reverse-engineering>;
        opencode = <FTS.coding._.tools/opencode>;
        "dev-tools" = <FTS.coding._.tools/dev-tools>;
        docker = <FTS.coding._.tools._.containers/docker>;
        podman = <FTS.coding._.tools._.containers/podman>;
      };
    in
    den.lib.parametric {
      includes =
        lib.optional cli <FTS.coding/cli>
        ++ lib.optional git <FTS.coding._.tools/git>
        ++ lib.optional lazygit <FTS.coding._.tools/lazygit>
        ++ lib.optional devTools <FTS.coding._.tools/dev-tools>
        ++ map (e: editorMap.${e}) editors
        ++ map (t: terminalMap.${t}) terminals
        ++ map (s: shellMap.${s}) shells
        ++ map (l: langMap.${l}) langs
        ++ map (t: toolMap.${t}) tools;
    };
}
