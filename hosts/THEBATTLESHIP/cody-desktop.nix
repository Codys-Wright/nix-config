# cody's desktop on THEBATTLESHIP: studio-linux (github:Codys-Wright/studio-linux)
# as the niri shell. The other users keep the host's shell (Noctalia) and the
# login screen stays the host's — this is cody's alone.
{ ... }:
{
  den.aspects."cody@THEBATTLESHIP".homeManager.programs.studio-linux.enable = true;
}
