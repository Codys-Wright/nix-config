# fleet-t3: drive T3 Code threads on other fleet machines (stdio MCP server +
# CLI). Standard-library Python; see fleet_t3.py's docstring for the design.
{
  lib,
  stdenvNoCC,
  makeWrapper,
  python3,
  openssh,
}:
stdenvNoCC.mkDerivation {
  pname = "fleet-t3";
  version = "0.1.0";
  src = ./fleet_t3.py;
  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    install -Dm644 $src $out/libexec/fleet-t3/fleet_t3.py
    # FLEET_T3_BIN: how a watch re-launches this program as its detached watcher.
    makeWrapper ${python3.interpreter} $out/bin/fleet-t3 \
      --add-flags "-I $out/libexec/fleet-t3/fleet_t3.py" \
      --set FLEET_T3_BIN $out/bin/fleet-t3 \
      --suffix PATH : ${lib.makeBinPath [ openssh ]}
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/fleet-t3 --version
    # The MCP handshake and tool list work without a config or network.
    printf '%s\n' \
      '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18"}}' \
      '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' \
      | $out/bin/fleet-t3 mcp | grep -q '"thread_watch"'
  '';

  meta = {
    description = "Start, read, steer and watch T3 Code threads on other fleet machines";
    mainProgram = "fleet-t3";
    platforms = lib.platforms.unix;
  };
}
