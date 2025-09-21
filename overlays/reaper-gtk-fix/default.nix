{
  channels,
  namespace ? "internal",
  inputs,
  ...
}:

final: prev: {
  # Override Reaper to include GTK3 in the LD_LIBRARY_PATH
  reaper = prev.reaper.overrideAttrs (oldAttrs: {
    installPhase = ''
      runHook preInstall

      HOME="$out/share" XDG_DATA_HOME="$out/share" ./install-reaper.sh \
        --install $out/opt \
        --integrate-user-desktop
      rm $out/opt/REAPER/uninstall-reaper.sh

      # Dynamic loading of plugin dependencies does not adhere to rpath of
      # reaper executable that gets modified with runtimeDependencies.
      # Patching each plugin with DT_NEEDED is cumbersome and requires
      # hardcoding of API versions of each dependency.
      # Setting the rpath of the plugin shared object files does not
      # seem to have an effect for some plugins.
      # We opt for wrapping the executable with LD_LIBRARY_PATH prefix.
      # Note that libcurl and libxml2 are needed for ReaPack to run.
      # Added gtk3 to fix libSwell GTK dependency issues
      wrapProgram $out/opt/REAPER/reaper \
        --prefix LD_LIBRARY_PATH : "${
          prev.lib.makeLibraryPath [
            prev.curl
            prev.lame
            prev.libxml2
            prev.ffmpeg
            prev.vlc
            prev.xdotool
            prev.stdenv.cc.cc
            prev.gtk3  # Added GTK3 for libSwell
          ]
        }"

      mkdir $out/bin
      ln -s $out/opt/REAPER/reaper $out/bin/

      runHook postInstall
    '';
  });
}
