# Android development SDK with emulator
{ FTS, ... }:
{
  FTS.coding._.tools._.android = {
    description = "Android SDK with build tools, platform tools, emulator, and system images";

    nixos =
      { pkgs, ... }:
      let
        androidEnv = pkgs.androidenv.override { licenseAccepted = true; };
        androidSdk = androidEnv.composeAndroidPackages {
          cmdLineToolsVersion = "13.0";
          platformToolsVersion = "35.0.2";
          buildToolsVersions = [
            "35.0.0"
            "34.0.0"
          ];
          platformVersions = [
            "35"
            "34"
          ];
          abiVersions = [
            "arm64-v8a"
            "x86_64"
          ];
          includeEmulator = true;
          includeSystemImages = true;
          systemImageTypes = [ "google_apis_playstore" ];
          includeNDK = true;
          ndkVersions = [ "27.2.12479018" ];
        };
      in
      {
        environment.systemPackages = with pkgs; [
          androidSdk.androidsdk
          android-studio
          android-tools # adb, fastboot
          jdk17
          gradle
        ];

        environment.variables = {
          ANDROID_SDK_ROOT = "${androidSdk.androidsdk}/libexec/android-sdk";
          ANDROID_HOME = "${androidSdk.androidsdk}/libexec/android-sdk";
          ANDROID_NDK_HOME = "${androidSdk.androidsdk}/libexec/android-sdk/ndk/27.2.12479018";
          JAVA_HOME = "${pkgs.jdk17}";
        };

        # KVM group for hardware-accelerated emulator
        users.groups.kvm = { };
        users.groups.adbusers = { };
      };
  };
}
