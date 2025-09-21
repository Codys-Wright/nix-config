Overlays
Snowfall Lib automatically exports your overlays and applies them to your NixPkgs instance used within your flake. This includes making the overlaid packages available to packages in your flake, NixOS systems, Darwin systems, Home Manager, modules, and overlays.

To create a new overlay, add a new directory to your overlays directory.

Note

Remember to run git add when creating new files!

Terminal window
```nix
# Create a directory in the `overlays` directory for a new overlay.
mkdir -p ./overlays/my-overlay
```

Now create the Nix file for the overlay at overlays/my-overlay/default.nix.

```nix
# Snowfall Lib provides access to additional information via a primary argument of
# your overlay.
{
# Channels are named after NixPkgs instances in your flake inputs. For example,
# with the input `nixpkgs` there will be a channel available at `channels.nixpkgs`.
# These channels are system-specific instances of NixPkgs that can be used to quickly
# pull packages into your overlay.
channels,

# The namespace used for your Flake, defaulting to "internal" if not set.
namespace,

# Inputs from your flake.
inputs,
... }:

final: prev: {
    # For example, to pull a package from unstable NixPkgs make sure you have the
    # input `unstable = "github:nixos/nixpkgs/nixos-unstable"` in your flake.
    inherit (channels.unstable) chromium;

    my-package = inputs.my-input.packages.${prev.system}.my-package;
}
```

This overlay will be made available on your flake’s overlays output with the same name as the directory that you created.