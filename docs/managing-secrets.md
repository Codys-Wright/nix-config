# Managing Secrets

All secrets live in the **private** repo `github.com/Codys-Wright/nix-secrets`
(checkout: `~/nix-secrets`, override with `$NIX_SECRETS_DIR`), consumed here as
the `nix-secrets` flake input. This repo is public: nothing secret, not even
encrypted per-host `secrets.yaml` files, lives in it.

## Layout (in nix-secrets)

| Path | Contents | Decrypted by |
|---|---|---|
| `sops/hosts/<host>.yaml` | host secrets (runner tokens, `keys/age`, …) | the host's SSH host key (`/etc/ssh/ssh_host_ed25519_key` via ssh-to-age) |
| `sops/users/<user>.yaml` | user secrets | the user's age key, `~/.config/sops/age/keys.txt` |
| `sops/shared.yaml` | fleet-wide secrets | hosts + users listed in `.sops.yaml` |
| `nix/*.nix` | **soft** vars (domains, LAN/VPN IPs, emails) as plain flake outputs | nobody — not secret |

Soft vars are read directly: `inputs.nix-secrets.networking.domains.selfhost`,
`inputs.nix-secrets.networking.hosts.starcommand.vpnIp`. Don't hard-code them.

## Using a secret in a module

```nix
{ inputs, ... }:
{
  fleet.some.aspect.nixos = { config, ... }: {
    imports = [ inputs.sops-nix.nixosModules.default ];
    sops.secrets."myservice/token" = {
      sopsFile = "${inputs.nix-secrets}/sops/hosts/THEBATTLESHIP.yaml";
      owner = "myservice";
    };
    services.myservice.tokenFile = config.sops.secrets."myservice/token".path;
  };
}
```

- Always `sops.validateSopsFiles = false` for input-based files (store paths
  can't be validated at eval time).
- Keys in the YAML are nested; `/` in the secret name is the separator.
- Home-manager secrets: `<fleet/user-secrets>` (in `den.default`) imports the
  sops-nix HM module and points `defaultSopsFile` at
  `sops/users/<username>.yaml`. The host secret `keys/age` bootstraps the
  user's age key into `~/.config/sops/age/keys.txt`
  (see `hosts/THEBATTLESHIP/sops.nix`).

## Workflow

```bash
just edit-secrets <name>            # user file preferred; --host / --user to force
git -C ~/nix-secrets commit -am "…" && git -C ~/nix-secrets push   # push FIRST
just update-secrets                 # repin the nix-secrets input (required)
```

`just update-secrets` refuses to run with unpushed commits — hosts evaluate
the pushed revision, so repinning early would pin the old secrets.

Key changes (`.sops.yaml` in nix-secrets): `just rekey-secrets`. Enroll a new
host with `just add-host <name> <ip>` inside `~/nix-secrets`.
Other helpers: `just sops-gen-key`, `just sops-get-host-key <host>`,
`just sops-gen-secret`.

## Never commit

`sops.key`, `keys.txt`, or any decrypted value — anywhere in this repo.
