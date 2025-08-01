{
  lib,
  inputs,
  namespace,
  pkgs,
  stdenv,
  fetchurl,
  wine,
  ...
}:

stdenv.mkDerivation rec {
  pname = "fabfilter-total-bundle";
  version = "1.0.0";

  src = fetchurl {
    url = "https://cdn-b.fabfilter.com/downloads/fftotalbundlex64.exe";
    sha256 = "sha256-oDwSjWWRQP0gPL+RSStbbWVhTmZM3vRppJJMuSLKbqk=";
  };

  nativeBuildInputs = with pkgs; [
    wine
  ];

  buildInputs = with pkgs; [
    wine
  ];

  # Skip unpack phase since we're dealing with a single .exe file
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    
    # Create installation directory
    mkdir -p $out/share/fabfilter-total-bundle
    
    # Copy the installer
    cp $src $out/share/fabfilter-total-bundle/fftotalbundlex64.exe
    
    # Create a wrapper script for installation
    cat > $out/bin/fabfilter-total-bundle-install <<EOF
    #!${pkgs.bash}/bin/bash
    echo "Installing FabFilter Total Bundle..."
    echo "This will install the plugins to your Wine prefix"
    echo "Make sure you have Wine configured properly"
    
    # Set up Wine environment
    export WINEPREFIX=\$HOME/.wine
    export WINEARCH=win64
    
    # Run the installer
    wine $out/share/fabfilter-total-bundle/fftotalbundlex64.exe
    EOF
    
    chmod +x $out/bin/fabfilter-total-bundle-install
    
    # Create a README
    cat > $out/share/fabfilter-total-bundle/README.md <<EOF
    # FabFilter Total Bundle
    
    This package contains the FabFilter Total Bundle installer.
    
    ## Installation
    
    Run the installer with:
    \`\`\`bash
    fabfilter-total-bundle-install
    \`\`\`
    
    ## Requirements
    
    - Wine must be installed and configured
    - A valid FabFilter license is required
    
    ## Notes
    
    - The installer will create Wine registry entries
    - Plugins will be available in DAWs that support VST in Wine
    - Make sure your DAW is configured to scan Wine VST directories
    EOF
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "FabFilter Total Bundle - Professional Audio Plugins";
    homepage = "https://www.fabfilter.com/products/total-bundle";
    license = licenses.unfree;
    platforms = platforms.linux;
    maintainers = [ ];
  };
} 