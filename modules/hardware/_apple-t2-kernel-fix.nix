# WORKAROUND (2026-10): rebase nixos-hardware's stable T2 kernel patch set onto
# current nixpkgs 6.18.x. Plain Nix (underscore = invisible to import-tree);
# used by modules/hardware/apple-t2.nix.
#
# nixos-hardware (apple/t2/pkgs/linux-t2/stable.json) still pins
# t2linux/linux-t2-patches @ facf1c7, which was cut for 6.18.29. nixpkgs is
# now at 6.18.54 and two parts of that set no longer apply:
#
#   * 3001-applesmc-convert-static-structures-to-drvdata: hunk #47 fails —
#     6.18.y backported the applesmc LED-workqueue error-path change
#     (`ret = led_classdev_register(...); if (ret) destroy_workqueue(...)`).
#   * 4005-HID-magicmouse-fix-regression…: hunk #2 fails — 6.18.y grew its
#     own magicmouse_reset_resume, so t2linux reworked the trackpad stack
#     (4001/4003/4004, 4005 folded in and deleted; "Fix trackpad" 05f8dce).
#
#   * 2008-i915-4-lane-quirk-for-mbp15-1: fails from 6.18.59 (intel_quirks.c
#     hunk #2, intel_quirks.h hunk #1) — 6.18.y moved the i915 quirk table.
#
# t2linux's 6.18 branch carries rebased copies; we take exactly those (3001
# and 4001-4004 pinned to 9f538c6, "Fix patching failure in patch 3001",
# KVER=6.18.53; 2008 pinned to 166c92f, "6.18.55") and keep every other patch
# from nixos-hardware unchanged. We deliberately do NOT
# adopt that branch wholesale: it renamed apple-bce to the t2bce driver stack,
# which would also need nixos-hardware's Kconfig + initrd module list forked.
#
# Removal: once nixos-hardware bumps stable.json off facf1c7, `needed` turns
# false, apple-t2.nix stops using this and emits a warning — then delete this
# file and its wiring in apple-t2.nix.
{
  lib,
  pkgs,
  nixos-hardware,
}:
let
  stalePatchesRev = "facf1c778667c3ef62104949ef64c75ce7e43b0a";
  trackpadRev = "9f538c646581ad805d9b4ff8690803306e3899db";
  i915QuirkRev = "166c92fba00154e1c66d2d690a30c3e6d4e51df1";

  # name -> rev and hash of the rebased copy on t2linux's 6.18 branch
  rebased = {
    "2008-i915-4-lane-quirk-for-mbp15-1.patch" = {
      rev = i915QuirkRev;
      hash = "sha256-gTYP7WHV/Qulobdi1nNdYsv1CWgkM8pGvsCFQ+rvhrw=";
    };
    "3001-applesmc-convert-static-structures-to-drvdata.patch" = {
      rev = trackpadRev;
      hash = "sha256-c/d+c5eKzhbtfUKtLC7AB+6vMXge4ZzPJAUbNENWH7g=";
    };
    "4001-asahi-trackpad.patch" = {
      rev = trackpadRev;
      hash = "sha256-2h3TdPsX9HBXx5jkZ2S2GJkjFcdL8vKD1G69iqd9IWg=";
    };
    "4003-HID-apple-ignore-the-trackpad-on-T2-Macs.patch" = {
      rev = trackpadRev;
      hash = "sha256-LLZzcysLTuQrSXWXbdq7AASxfMInQoqpWzRNZAKws9k=";
    };
    "4004-HID-magicmouse-Add-support-for-trackpads-found-on-T2.patch" = {
      rev = trackpadRev;
      hash = "sha256-kUnbtl/54cihscirl9kP0Gsot7bdP0rYKlj6gQ10hk0=";
    };
  };
  dropped = [ "4005-HID-magicmouse-fix-regression-breaking-support-for-M.patch" ];

  linuxT2 = "${nixos-hardware}/apple/t2/pkgs/linux-t2";
  upstreamPatchset = lib.importJSON "${linuxT2}/stable.json";
  upstreamKernel = pkgs.callPackage linuxT2 { };

  fixPatch =
    p:
    if rebased ? ${p.name} then
      p
      // {
        patch = pkgs.fetchurl {
          inherit (p) name;
          url = "https://raw.githubusercontent.com/t2linux/linux-t2-patches/${rebased.${p.name}.rev}/${p.name}";
          inherit (rebased.${p.name}) hash;
        };
      }
    else
      p;
in
{
  needed = lib.hasInfix stalePatchesRev upstreamPatchset.base_url;

  # A plain `.override { kernelPatches = …; }` lands on nixos-hardware's
  # callPackage layer, which *appends* to its own list; its generic.nix merges
  # `argsOverride` last into the nixpkgs kernel override, so a replacement
  # list has to go there.
  kernel = upstreamKernel.override {
    argsOverride.kernelPatches = map fixPatch (
      builtins.filter (p: !(builtins.elem p.name dropped)) upstreamKernel.kernelPatches
    );
  };
}
