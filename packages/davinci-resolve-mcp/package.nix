# DaVinci Resolve MCP server — exposes Resolve's scripting API as MCP tools
# (project/media-pool/timeline/color/Fusion/Fairlight/render) over stdio.
#
# Upstream has no releases, so the source is pinned by commit. Bump `version`
# (from its package.json) together with `rev`/`hash`.
#
# Two things upstream assumes that do not hold on NixOS, both handled here:
#   1. Resolve lives at /opt/resolve — we point RESOLVE_SCRIPT_API/LIB at the
#      unwrapped Resolve store path (`passthru.davinci`) instead, and add the
#      libs fusionscript.so needs but carries no rpath for (libuuid, libX11,
#      libxkbcommon) to LD_LIBRARY_PATH.
#   2. The server writes logs/ and update-check state next to its own source.
#      The store is read-only, so `project_dir` is redirected to a writable
#      state dir — after the sys.path setup that uses the same variable.
{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  runtimeShell,
  python3,
  ffmpeg,
  libuuid,
  libX11,
  libxkbcommon,
  fleet-davinci-resolve,
  # Match whichever Resolve edition the host installs — the scripting API is
  # identical between editions, but the store path is not.
  studioVariant ? true,
}:
let
  resolve = (fleet-davinci-resolve.override { inherit studioVariant; }).davinci;

  pythonEnv = python3.withPackages (ps: [
    ps.mcp # the server itself (src/server.py imports mcp.server.fastmcp)
    ps.numpy # optional: colour / waveform analysis tools
    ps.pillow # optional: thumbnail and still handling
  ]);
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "davinci-resolve-mcp";
  version = "2.89.0";

  src = fetchFromGitHub {
    owner = "samuelgursky";
    repo = "davinci-resolve-mcp";
    rev = "91cb68b66fecc80476073934d9040d1d3319dbec";
    hash = "sha256-xFnC18wz7FAL+UfnvM2pwEYNmjLgfYpViDP1HiO5zac=";
  };

  dontBuild = true;

  postPatch = ''
    substituteInPlace src/server.py --replace-fail \
      'log_dir = os.path.join(project_dir, "logs")' \
      'project_dir = os.environ.get("RESOLVE_MCP_STATE_DIR", project_dir)
    log_dir = os.path.join(project_dir, "logs")'
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/davinci-resolve-mcp
    cp -r src docs examples scripts $out/share/davinci-resolve-mcp/

    mkdir -p $out/bin
    cat > $out/bin/davinci-resolve-mcp <<'LAUNCHER'
    @shell@
    set -eu
    export RESOLVE_SCRIPT_API="@resolve@/Developer/Scripting"
    export RESOLVE_SCRIPT_LIB="@resolve@/libs/Fusion/fusionscript.so"
    export PYTHONPATH="@resolve@/Developer/Scripting/Modules:@share@''${PYTHONPATH:+:$PYTHONPATH}"
    export LD_LIBRARY_PATH="@libraryPath@''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    export PATH="@binPath@:$PATH"
    : "''${RESOLVE_MCP_STATE_DIR:=''${XDG_STATE_HOME:-$HOME/.local/state}/davinci-resolve-mcp}"
    export RESOLVE_MCP_STATE_DIR
    mkdir -p "$RESOLVE_MCP_STATE_DIR/logs"
    exec @python@/bin/python @share@/src/server.py "$@"
    LAUNCHER

    substituteInPlace $out/bin/davinci-resolve-mcp \
      --replace-fail '@shell@' '#!${runtimeShell}' \
      --subst-var-by resolve '${resolve}' \
      --subst-var-by share "$out/share/davinci-resolve-mcp" \
      --subst-var-by python '${pythonEnv}' \
      --subst-var-by libraryPath '${
        lib.makeLibraryPath [
          libuuid
          libX11
          libxkbcommon
        ]
      }' \
      --subst-var-by binPath '${lib.makeBinPath [ ffmpeg ]}'

    chmod +x $out/bin/davinci-resolve-mcp

    runHook postInstall
  '';

  meta = {
    description = "MCP server exposing the DaVinci Resolve scripting API";
    homepage = "https://github.com/samuelgursky/davinci-resolve-mcp";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "davinci-resolve-mcp";
  };
})
