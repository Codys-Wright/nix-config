# Angle Bracket Syntax Guide

## Overview

The angle bracket syntax is a shorthand for referencing aspects and providers in Den. It's enabled by default in your `modules/namespace.nix`.

## Resolution Rules

### 1. Namespace References (FTS, deployment, etc.)

```nix
<FTS/gdm>                 # → den.ful.FTS.gdm
<FTS/disk/disk>           # → den.ful.FTS.disk.provides.disk
(<FTS/grub> { })          # → (den.ful.FTS.grub { })
<deployment/default>      # → den.ful.deployment.default
```

**Pattern:** `<namespace/path>` resolves to `den.ful.<namespace>.<path with / → .provides.>`

### 2. Den Provides References

```nix
<den/home-manager>        # → den.provides.home-manager
<den/vm>                  # → den.provides.vm
<den/iso>                 # → den.provides.iso
(<den/unfree> true)       # → (den.provides.unfree true)
```

**Pattern:** `<den/name>` resolves to `den.provides.<name>`

### 3. Den Aspects (NO angle brackets)

For aspects directly under `den.aspects`, **keep the original syntax**:

```nix
den.aspects.hm-backup           # ✅ Keep as is
den.aspects.nix-index           # ✅ Keep as is
den.aspects.example._.routes    # ✅ Keep as is
```

**Why?** `<den/hm-backup>` would resolve to `den.provides.hm-backup`, not `den.aspects.hm-backup`.

## Complete Example

```nix
{ __findFile, ... }:
{
  den.aspects.THEBATTLESHIP = {
    includes = [
      # Namespace aspects - use angle brackets
      <FTS/gdm>
      <FTS/gnome>
      (<FTS/grub> { uefi = true; })
      
      # Nested namespace providers - use angle brackets
      (<FTS/disk/disk> {
        type = "btrfs-impermanence";
        device = "/dev/nvme0n1";
      })
      
      # Den provides - use angle brackets
      (<den/unfree> true)
      <den/home-manager>
      
      # Den aspects - use original syntax
      den.aspects.hm-backup
      den.aspects.nix-index
    ];
  };
}
```

## Benefits

1. **Shorter syntax**: `<FTS/gdm>` vs `FTS.gdm`
2. **Clear provider chains**: `<FTS/disk/disk>` shows the provider path
3. **Consistent with Den philosophy**: Uses the `/` separator like filesystem paths

## When to Use

- ✅ Use for namespace references (FTS, deployment, etc.)
- ✅ Use for `den.provides.*` references
- ❌ Don't use for `den.aspects.*` references (keep original syntax)

## Enabling in New Modules

If you need `__findFile` in a specific module scope:

```nix
{ __findFile, ... }:
{
  # Now you can use angle brackets in this module
  den.aspects.my-aspect.includes = [ <FTS/something> ];
}
```

It's already enabled globally in your `modules/namespace.nix`, so all modules have access to it.

