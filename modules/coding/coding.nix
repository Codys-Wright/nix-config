# Coding facet - Router for coding tools and environments
{
  FTS,
  lib,
  ...
}:
{
  FTS.coding.description = ''
    Coding tools and environments facet.
    
    Usage:
      # Include full coding setup
      (<FTS/coding> {
        cli = { default = "all"; };
        editors = { default = "cursor"; };
        terminals = { default = "ghostty"; };
        shells = { default = "fish"; };
        languages = { rust = {}; typescript = {}; };
        tools = { git = {}; docker = {}; };
      })
      
      # Include specific tools
      <FTS/coding/cli/fzf>
      <FTS/coding/editors/cursor>
      
    Categories: cli, editors, lang, shells, terminals, tools
  '';

  # Make coding callable as a router
  FTS.coding.__functor =
    _self:
    {
      cli ? null,
      editors ? null,
      lang ? null,
      shells ? null,
      terminals ? null,
      tools ? null,
      ...
    }@args:
    { class, aspect-chain }:
    let
      # Build includes based on what's provided
      cliIncludes = lib.optionals (cli != null) [ (FTS.coding._.cli cli) ];
      editorIncludes = lib.optionals (editors != null) [ (FTS.coding._.editors editors) ];
      langIncludes = lib.optionals (lang != null) [ (FTS.coding._.lang lang) ];
      shellIncludes = lib.optionals (shells != null) [ (FTS.coding._.shells shells) ];
      terminalIncludes = lib.optionals (terminals != null) [ (FTS.coding._.terminals terminals) ];
      toolIncludes = lib.optionals (tools != null) [ (FTS.coding._.tools tools) ];
    in
    {
      includes = cliIncludes ++ editorIncludes ++ langIncludes ++ shellIncludes ++ terminalIncludes ++ toolIncludes;
    };
}

