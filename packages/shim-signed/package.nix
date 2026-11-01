# shim-signed: Ubuntu's Microsoft-signed shim (UEFI CA 2011) and MokManager,
# unpacked from the shim-signed .deb. Factory Secure Boot keys trust shim;
# shim then trusts whatever is enrolled in its MOK list, so a host can
# Secure Boot NixOS without adding keys to the firmware
# (<fleet.lanzaboote/shim>).
#
#   share/shim/shimx64.efi  shimx64.efi.signed.latest (Microsoft UEFI CA 2011)
#   share/shim/mmx64.efi    MokManager (Canonical-signed; shim trusts it)
#
# Microsoft revokes old shims through SBAT updates from Windows Update: when
# one lands, bump to the newest shim-signed from Launchpad.
{
  lib,
  stdenvNoCC,
  fetchurl,
  dpkg,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "shim-signed";
  version = "1.59+15.8-0ubuntu2";

  # Launchpad's librarian keeps every published file; the archive pool drops
  # superseded ones.
  src = fetchurl {
    url = "https://launchpad.net/ubuntu/+archive/primary/+files/shim-signed_${finalAttrs.version}_amd64.deb";
    hash = "sha256-+O1xzi2RowS21euEmX+EbzMbVUV4vALb/njhOtisgak=";
  };

  nativeBuildInputs = [ dpkg ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    install -Dm444 usr/lib/shim/shimx64.efi.signed.latest $out/share/shim/shimx64.efi
    install -Dm444 usr/lib/shim/mmx64.efi $out/share/shim/mmx64.efi
    runHook postInstall
  '';

  meta = {
    description = "Ubuntu's Microsoft-signed shim and MokManager for x86_64 UEFI";
    homepage = "https://launchpad.net/ubuntu/+source/shim-signed";
    license = lib.licenses.bsd2;
    sourceProvenance = [ lib.sourceTypes.binaryFirmware ];
    platforms = [ "x86_64-linux" ];
  };
})
