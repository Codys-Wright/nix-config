{
  lib,
  pkgs,
  inputs,
  ...
}:

let
  # Fetch the latest lyp release
  lypRelease = pkgs.fetchurl {
    url = "https://github.com/noteflakes/lyp/releases/download/1.3.8/lyp-1.3.8-linux-x86_64.tar.gz";
    sha256 = "1gzp6l6ly3bbw3whi3sq7q7kdfd7igxy8pv4jim1waw0pygbx0gf";
  };
in

pkgs.stdenv.mkDerivation {
  pname = "lyp";
  version = "1.3.8";
  src = lypRelease;

  sourceRoot = ".";

  buildInputs = [ pkgs.ruby_3_1 ];

  installPhase = ''
    # Create the output directory
    mkdir -p $out

    # Extract the release to a temporary directory
    mkdir -p tmp
    tar -xzf $src -C tmp

    # Copy the contents from the extracted directory
    cp -r tmp/lyp-1.3.8-linux-x86_64/* $out/

    # Move the original lyp to lyp.real and make it executable
    mv $out/bin/lyp $out/bin/lyp.real
    chmod +x $out/bin/lyp.real

    # Create a wrapper script that sets up the environment
    echo '#!/bin/bash' > $out/bin/lyp
    echo 'export LD_LIBRARY_PATH="/nix/store/vbh0fkk1rhd4g81fcyqh6yldrdcn3x3v-libxcrypt-4.4.38/lib:$LD_LIBRARY_PATH"' >> $out/bin/lyp
    echo 'find "$(dirname "$0")/../lib" -name "package.rb" -exec sed -i "1i require \"uri\"" {} \; 2>/dev/null || true' >> $out/bin/lyp
    echo 'find "$(dirname "$0")/../lib" -name "package.rb" -exec sed -i "s/YAML.load(open(LYP_INDEX_URL))/YAML.load(URI.open(LYP_INDEX_URL))/g" {} \; 2>/dev/null || true' >> $out/bin/lyp
    echo 'exec "$(dirname "$0")/lyp.real" "$@"' >> $out/bin/lyp
    chmod +x $out/bin/lyp

    # Apply the Ruby 3.0+ patch to fix the open() issue
    find $out -name "package.rb" -exec sed -i '1i require "uri"' {} \;
    find $out -name "package.rb" -exec sed -i 's/YAML.load(open(LYP_INDEX_URL))/YAML.load(URI.open(LYP_INDEX_URL))/g' {} \;
  '';

  meta = with lib; {
    description = "LilyPond package manager (lyp) with Ruby 3.0+ compatibility";
    homepage = "https://github.com/noteflakes-music/lyp";
    license = licenses.mit;
    platforms = platforms.all;
  };
}