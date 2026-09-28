{ ... }:
{
  den.hosts.x86_64-linux.outrider = {
    description = "WSL system that goes where no other system has gone before (Windows)";
    users.cody = { };
    # den's wsl battery imports NixOS-WSL and sets wsl.enable; the
    # primary-user battery sets wsl.defaultUser.
    wsl.enable = true;
  };
}
