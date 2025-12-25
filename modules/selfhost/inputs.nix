# Flake inputs for self-hosting services
{
  lib,
  ...
}:
{
  # Using local fork with Jellyfin SSO fixes (DisablePushedAuthorization, scopes, auth method)
  # TODO: Switch back to upstream once PR is merged
  flake-file.inputs.selfhostblocks.url = lib.mkDefault "path:/home/cody/Documents/Development/nix/selfhostblocks";
  
  # DON'T follow our nixpkgs - let selfhostblocks use its own patched version
  # This gives us access to patched modules via inputs.selfhostblocks
  
  # sops-nix is already in the main flake inputs via deployment module
  # but we ensure it's available here too
  flake-file.inputs.sops-nix.url = lib.mkDefault "github:Mic92/sops-nix";
}

