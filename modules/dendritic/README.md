# Dendritic Modules (Legacy)

This folder contains legacy infrastructure modules used before migrating to den's built-in batteries.

## Modules

### `host.nix`
Legacy hostname provider. Hostname is now provided by `FTS.hostname`.

### `home.nix`
Legacy home provider.

```nix
# Automatically sets home.username and home.homeDirectory
Replaced by: `<den/define-user>`
```

### `user.nix`
Legacy user provider.

```nix
# Creates user accounts with isNormalUser = true
Replaced by: `<den/define-user>`
```

### `routes.nix`
Legacy compatibility no-op.

```nix
Kept only to avoid breaking imports that still reference it.
```

## Usage

Current defaults use den batteries (see `modules/aspects/defaults.nix`):

```nix
den.default = {
  includes = [
    <den/define-user>
    <FTS/hostname>
    <FTS/state-version>
    # ... other defaults
  ];
};
```
