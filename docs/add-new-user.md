# Adding a New User

A user is a `den.aspects.<name>` aspect (plus optionally a standalone
`den.homes` entry) and one `users.<name> = { };` line on each host they live
on. Conventions: [CLAUDE.md](../CLAUDE.md), [den-conventions.md](den-conventions.md).

## 1. User file

```nix
# users/alex/alex.nix
{ __findFile, ... }:
{
  den.homes.x86_64-linux.alex.userName = "alex";   # optional standalone home

  den.aspects.alex = {
    description = "Alex — what this account is for";

    includes = [
      (<fleet.user/password> { method = "hashed"; value = "$6$…"; })  # mkpasswd -m sha-512
      (<fleet.user/shell> "fish")          # or (<den/user-shell> "bash")
      (<fleet.user/groups> [ "video" ])    # NixOS groups for this user
      <fleet/apps>                         # user-picked features
    ];

    user.description = "Alex";             # → users.users.alex.*

    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.htop ];
    };
  };
}
```

## 2. Put the user on a host

```nix
den.hosts.x86_64-linux.THEBATTLESHIP.users.alex = { };
# per-host groups:  users.alex.extraGroups = [ "audio" ];
```

## Account kinds

| Kind | Include | Gets |
|---|---|---|
| admin | `<den/primary-user>` `<fleet.user/admin>` | wheel, networkmanager, and every `admin-groups` group (docker, libvirtd, podman) |
| co-op gaming | `<fleet.user/coop-player>` | bash, session device groups, Proton tooling (bri, carter) |
| restricted (child/kiosk) | `<fleet.user/restricted>` | skips the per-user halves host features hand out (joshua) |
| guest | plain aspect | whatever it lists (users/guest) |

Only admins get root-equivalent groups — aspects add those through
`(<fleet.user/admin-groups> [ … ])`.

## Where things land

- `homeManager` on the user aspect → that user's home.
- `user = { … }` → `users.users.<name>` on every host the user is on
  (NixOS-only fields like `extraGroups` go through `<fleet.user/groups>`,
  which skips nix-darwin).
- System config the user needs on their hosts → `provides.to-hosts.nixos`
  (or `provides.<HOST>.nixos` for one host). Don't write a bare `nixos` block
  on a user aspect (den bug #694).
- Host features with a per-user half (gaming, desktop) arrive automatically
  through `provides.to-users`.

## 3. Secrets

User secrets: `sops/users/<name>.yaml` in `~/nix-secrets`
(`just edit-secrets <name> --user`), consumed by `<fleet/user-secrets>`.
Then `git add users/alex` and `just build-host <host>`.
