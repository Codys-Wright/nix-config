# Linters configuration
# Returns config.vim settings directly
# Takes lib as parameter for consistency (even if not used)
# 
# Note: In nvf, most linters are configured per-language through the language modules
# (e.g., languages.nix.extraDiagnostics for statix/deadnix).
# This file is for global linter configuration if needed.
{lib, ...}: {
  # Global linter configuration
  # Most language-specific linters are configured in lang.nix via extraDiagnostics
  # For example:
  # - Nix: statix, deadnix (configured in languages.nix.extraDiagnostics)
  # - Other languages: configured in their respective language modules
  
  # If you need global nvim-lint configuration, you can add it here:
  # diagnostics.nvim-lint = {
  #   enable = true;
  #   linters_by_ft = {
  #     # Global filetype linter mappings
  #   };
  #   linters = {
  #     # Global linter configurations
  #   };
  # };
}
