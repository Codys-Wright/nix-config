# Package test aspect - adds test packages to system
{ FTS, ... }:
{
  FTS.package-test = {
    description = "Test aspect that adds cowsay, hello, and vim to system packages";

    nixos = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        cowsay
        hello
        vim
      ];
    };
  };
}

