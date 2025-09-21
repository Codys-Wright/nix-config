{
  lib,
  pkgs,
  inputs,
  ...
}:

let
  # Apply patch to fix Ruby 3.0+ open() issue
  patchedLyp = pkgs.stdenv.mkDerivation {
    name = "lyp-patched";
    src = ./.;
    patches = [ ./ruby3-open-uri-fix.patch ];
    installPhase = ''
      cp -r . $out
    '';
  };
  
  gems = pkgs.bundlerEnv {
    name = "lyp-gems";
    ruby = pkgs.ruby_3_1;
    gemdir = patchedLyp;
  };
in

pkgs.stdenv.mkDerivation {
  pname = "lyp";
  version = "1.3.11";
  src = patchedLyp;
  
  buildInputs = [ gems pkgs.ruby_3_1 pkgs.cacert ];
  
  installPhase = ''
    mkdir -p $out/bin
    cp ${gems}/bin/lyp $out/bin/
    
    # Create a wrapper script that sets SSL environment variables
    cat > $out/bin/lyp << 'EOF'
#!/bin/sh
export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
export SSL_CERT_DIR=${pkgs.cacert}/etc/ssl/certs
exec ${gems}/bin/lyp "$@"
EOF
    chmod +x $out/bin/lyp
  '';
  
  meta = with lib; {
    description = "LilyPond package manager (lyp) pinned with bundix";
    homepage = "https://github.com/noteflakes/lyp";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
