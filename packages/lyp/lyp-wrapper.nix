{ pkgs, lyp }:

pkgs.writeShellScriptBin "lyp" ''
  # Find the lyp gem directory
  LYP_GEM_DIR=$(find ${lyp} -name "lyp-*.gem" -o -name "lyp" -type d | head -1)
  
  # Create a temporary patched version
  TEMP_DIR=$(mktemp -d)
  cp -r "$LYP_GEM_DIR"/* "$TEMP_DIR/"
  
  # Apply the Ruby 3.0+ open() fix
  find "$TEMP_DIR" -name "*.rb" -exec sed -i '1i require "uri"' {} \;
  find "$TEMP_DIR" -name "*.rb" -exec sed -i 's/open(index_url)/URI.open(index_url)/g' {} \;
  
  # Run lyp with the patched version
  export GEM_PATH="$TEMP_DIR:$GEM_PATH"
  exec ${lyp}/bin/lyp "$@"
''
