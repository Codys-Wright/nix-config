# Dendritic Modules

This folder contains essential infrastructure modules that work with den's parametric system. These modules provide the foundational configuration needed for den's default aspect.

## Modules

### `host.nix`
Legacy host plumbing placeholder. Hostname is now provided by `FTS.hostname`.

### `home.nix`
Configures home directory and username for home-manager based on den's home context.

```nix
# Automatically sets home.username and home.homeDirectory
den.aspects.dendritic._.home
```

### `user.nix`
Sets up basic user accounts on nixos and darwin systems.

```nix
# Creates user accounts with isNormalUser = true
den.aspects.dendritic._.user
```

### `routes.nix`
Implements a routing pattern for mutual dependencies between aspects.

```nix
# Allows aspects to reference each other mutually
# Example: user aspect can include host-specific config and vice versa
den.aspects.dendritic._.routes
```

## Usage

These modules are automatically included in `den.default` (see `modules/aspects/defaults.nix`):

```nix
den.default = {
  includes = [
    den.aspects.dendritic._.routes
    den.aspects.dendritic._.user
    den.aspects.dendritic._.home
    <FTS/hostname>
    <FTS/state-version>
    # ... other defaults
  ];
};
```

## Why "Dendritic"?

The name "dendritic" comes from dendrites in neuroscience - the branching extensions that receive signals and connect neurons. Similarly, these modules provide the foundational connections that allow den aspects to communicate and work together in the parametric system.

These are the "dendrites" of your flake - the infrastructure that connects everything together! 🌳
