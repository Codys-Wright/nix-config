# Apple T2 Mac support (2018-2020 Intel Macs with T2 security chip)
#
# Pulls t2linux-patched kernel + drivers from nixos-hardware's apple-t2 module
# (keyboard, trackpad, touchbar, audio, Wi-Fi/BT, thermals) and wires up the
# t2linux cachix so you are not compiling a custom kernel locally. (While the
# kernel-patch workaround below is active the kernel is a local derivation,
# so it is compiled locally.)
#
# Post-install firmware step: Wi-Fi and Bluetooth need blobs extracted from a
# macOS recovery image. See https://wiki.t2linux.org — once blobs are installed,
# flip `hardware.apple-t2.firmware.enable = true` on the host.
#
# Usage: include `<fleet.hardware/apple-t2>` on any T2 Mac host.
{
  inputs,
  fleet,
  ...
}:
{
  flake-file.inputs.nixos-hardware.url = "github:NixOS/nixos-hardware";

  fleet.hardware._.apple-t2 = {
    description = "Apple T2 Mac kernel + drivers (2018-2020 Intel Macs)";

    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        # WORKAROUND (2026-10): nixos-hardware's stable t2linux patches no
        # longer apply to nixpkgs' 6.18.x; see ./_apple-t2-kernel-fix.nix.
        # Remove this, the two definitions below and that file once the
        # warning fires (nixos-hardware has bumped its patch set).
        t2KernelFix = import ./_apple-t2-kernel-fix.nix {
          inherit lib pkgs;
          inherit (inputs) nixos-hardware;
        };
      in
      {
        imports = [ inputs.nixos-hardware.nixosModules.apple-t2 ];

        boot.kernelPackages = lib.mkIf (
          config.hardware.apple-t2.kernelChannel == "stable" && t2KernelFix.needed
        ) (lib.mkForce (pkgs.linuxPackagesFor t2KernelFix.kernel));
        warnings = lib.optional (!t2KernelFix.needed) ''
          fleet.hardware.apple-t2: nixos-hardware has moved its T2 patch set
          off t2linux facf1c7 — drop the kernel workaround
          (modules/hardware/_apple-t2-kernel-fix.nix + its wiring in apple-t2.nix).
        '';

        hardware.apple-t2.kernelChannel = lib.mkDefault "stable";

        hardware.apple-t2.firmware.enable = lib.mkDefault false;
        hardware.apple-t2.firmware.version = lib.mkDefault "sonoma";

        hardware.apple.touchBar.enable = lib.mkDefault true;

        nix.settings.trusted-substituters = [ "https://t2linux.cachix.org" ];
        nix.settings.trusted-public-keys = [
          "t2linux.cachix.org-1:P733c5Gt1qTcxsm+Bae0renWnT8OLs0u9+yfaK2Bejw="
        ];
      };
  };

  # Steam's CEF UI segfaults on the T2's half-initialized iGPU; run only the
  # client UI in software (games still render on the GPU). Per-user file, so
  # it rides provides.to-users to everyone on the host.
  fleet.hardware._.apple-t2._.steam-cef-fix = {
    description = "Steam desktop entry override — -cef-disable-gpu to avoid CEF SIGSEGV on T2 half-initialized iGPU";
    provides.to-users.homeManager.home.file.".local/share/applications/steam.desktop".text = ''
      [Desktop Entry]
      Name=Steam
      Comment=Application for managing and playing games on Steam
      Exec=steam -cef-disable-gpu %U
      Icon=steam
      Terminal=false
      Type=Application
      Categories=Network;FileTransfer;Game;
      MimeType=x-scheme-handler/steam;x-scheme-handler/steamlink;
      PrefersNonDefaultGPU=true
    '';
  };
}
