# Adding a New User

This guide walks you through adding a new user to your NixOS/Darwin configuration.

## Overview

Adding a new user involves:
1. Creating the user directory structure
2. Creating the user configuration file
3. Defining the user aspect
4. Optionally setting up secrets
5. Adding the user to hosts

## Step-by-Step Guide

### Step 1: Create User Directory

Create a directory for your new user:

```bash
mkdir -p users/alice
cd users/alice
```

### Step 2: Create User Configuration File

Create `users/alice/alice.nix`:

```nix
{ inputs, den, pkgs, FTS, ... }:
{
  # Define the user
  den.users = {
    alice = {
      description = "Alice's user configuration";
      aspect = "alice";  # Reference to the aspect below
    };
  };

  # Define the user's aspect (configuration)
  den.aspects = {
    alice = {
      # Include aspects that apply to this user
      includes = [
        # Add user-specific aspects here
        # FTS.editors
        # FTS.coding
        # etc.
      ];

      # Home Manager configuration for this user
      homeManager = { config, lib, pkgs, ... }: {
        # Basic user info
        home.username = "alice";
        home.homeDirectory = "/home/alice";

        # User-specific packages
        home.packages = with pkgs; [
          # Add packages here
        ];

        # User-specific configuration
        # For example:
        # programs.git = {
        #   enable = true;
        #   userName = "Alice";
        #   userEmail = "alice@example.com";
        # };
      };
    };
  };
}
```

### Step 3: Add User to Hosts

To make the user available on specific hosts, add them to the host configuration:

```nix
# hosts/myserver/myserver.nix
{ inputs, den, pkgs, FTS, ... }:
{
  den.hosts.x86_64-linux = {
    myserver = {
      description = "My server";
      users.alice = { };  # Add alice to this host
      users.cody = { };   # Other users...
      aspect = "myserver";
    };
  };

  # ... rest of host configuration
}
```

### Step 4: Create Secrets File (Optional)

If you're using SOPS for secrets management:

```bash
cd /home/cody/.flake

# Create encrypted secrets file for this user
just edit-secrets alice
# This will create users/alice/secrets.yaml if it doesn't exist

# Add user-specific secrets:
# - SSH keys
# - API tokens
# - Service credentials
# etc.
```

### Step 5: Regenerate Flake

After creating the user configuration, regenerate your flake:

```bash
nix run .#write-flake
```

### Step 6: Test the Configuration

Build the configuration to check for errors:

```bash
# Build for a specific host that includes this user
just build myserver

# Or check if it evaluates correctly
nix flake check
```

### Step 7: Switch/Deploy

Apply the configuration:

```bash
# If local
just switch myserver

# If remote
nix run .#deploy-rs -- --hosts myserver
```

## Complete Example

Here's a complete example for a developer user:

```nix
# users/bob/bob.nix
{ inputs, den, pkgs, FTS, ... }:
{
  den.users = {
    bob = {
      description = "Bob's developer configuration";
      aspect = "bob";
    };
  };

  den.aspects = {
    bob = {
      includes = [
        FTS.editors      # Include editor configuration
        FTS.coding       # Include coding tools
      ];

      homeManager = { config, lib, pkgs, ... }: {
        home.username = "bob";
        home.homeDirectory = "/home/bob";

        # Developer packages
        home.packages = with pkgs; [
          git
          vim
          curl
          jq
        ];

        # Git configuration
        programs.git = {
          enable = true;
          userName = "Bob Developer";
          userEmail = "bob@example.com";
          extraConfig = {
            init.defaultBranch = "main";
          };
        };

        # Shell configuration
        programs.zsh = {
          enable = true;
          ohMyZsh = {
            enable = true;
            theme = "robbyrussell";
            plugins = [ "git" "docker" ];
          };
        };
      };
    };
  };
}
```

Then add to hosts:

```nix
# hosts/devserver/devserver.nix
den.hosts.x86_64-linux = {
  devserver = {
    description = "Development server";
    users.bob = { };  # Bob has access to this server
    aspect = "devserver";
  };
};
```

## User Aspects

You can include various aspects in a user's configuration:

### Common Aspects

- `FTS.editors` - Editor configurations (lazyvim, neovim, etc.)
- `FTS.coding` - Coding tools and languages
- `FTS.desktop` - Desktop environment settings
- `FTS.gaming` - Gaming tools and configurations
- `FTS.hardware` - Hardware-specific settings

### Example with Multiple Aspects

```nix
den.aspects = {
  alice = {
    includes = [
      FTS.editors
      FTS.coding
      FTS.desktop
    ];

    homeManager = { ... }: {
      # User-specific overrides
    };
  };
};
```

## User Secrets

If using SOPS, user secrets are stored in `users/USERNAME/secrets.yaml`:

```yaml
# users/alice/secrets.yaml
ssh:
  private_key: "encrypted-key"
  public_key: "encrypted-key"

api:
  github_token: "encrypted-token"
  gitlab_token: "encrypted-token"
```

Access in configuration:

```nix
homeManager = { config, ... }: {
  # Reference secrets from sops-nix
  programs.ssh = {
    enable = true;
    # Use secrets from sops
  };
};
```

## Quick Reference

### Directory Structure

```
users/
  alice/
    alice.nix          # User configuration
    secrets.yaml        # Encrypted secrets (if using SOPS)
```

### Common Commands

```bash
# Create/edit user secrets
just edit-secrets alice

# Build configuration with user
just build myserver

# Switch configuration (local)
just switch myserver

# Deploy configuration (remote)
nix run .#deploy-rs -- --hosts myserver
```

## User vs Host Configuration

- **User configuration** (`users/USERNAME/USERNAME.nix`):
  - Home Manager settings
  - User-specific packages
  - User preferences
  - Shell configuration
  - Editor settings

- **Host configuration** (`hosts/HOSTNAME/HOSTNAME.nix`):
  - System-wide settings
  - Services
  - Network configuration
  - Which users have access

## Adding User to Multiple Hosts

You can add the same user to multiple hosts:

```nix
# hosts/laptop/laptop.nix
den.hosts.x86_64-linux = {
  laptop = {
    users.alice = { };
    aspect = "laptop";
  };
};

# hosts/server/server.nix
den.hosts.x86_64-linux = {
  server = {
    users.alice = { };
    aspect = "server";
  };
};
```

The user's aspect configuration applies to all hosts where they're added.

## Troubleshooting

### User Not Appearing

- Verify `users.USERNAME = { }` is in the host configuration
- Check that the user aspect is properly defined
- Ensure flake was regenerated: `nix run .#write-flake`

### Home Manager Not Working

- Verify `den.default.host.includes` includes home-manager
- Check that the user aspect has a `homeManager` class
- Ensure Home Manager is enabled on the host

### Secrets Not Accessible

- Verify `users/USERNAME/secrets.yaml` exists
- Check SOPS configuration in `sops.yaml`
- Ensure secrets are properly encrypted

## Next Steps

After adding your user:

1. **Configure user aspects** - Add editor, coding, desktop aspects
2. **Set up secrets** - Add SSH keys, API tokens, etc.
3. **Test on a host** - Build and switch to verify
4. **Iterate** - Add more configuration as needed

## See Also

- [Adding a New Host](./add-new-host.md) - How to add hosts
- [Managing Secrets](./managing-secrets.md) - SOPS secrets management
- [Deployment Module](../modules/deployment/README.md) - Remote deployment

