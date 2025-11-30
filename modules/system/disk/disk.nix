# Disk/filesystem configuration aspect
# Parametric wrapper that includes filesystem-specific modules based on configuration
{
  inputs,
  den,
  lib,
  FTS,
  ...
}:
let
  description = ''
    Disk and filesystem configuration aspect with support for different filesystem types.

    Can optionally take parameters for filesystem configuration:
      FTS.disk
      FTS.disk { type = "btrfs"; impermanence = true; }
      FTS.disk {
        type = "ext4";
        swapsize = "8G";
        device = "/dev/sda";
        encrypted = false; # TODO: Implement encryption support in the future
      }

    Available filesystem types: btrfs, ext4
    Options vary by filesystem type.
    Note: Encryption support is planned for future implementation.
  '';

  # Extract disk configuration from arguments
  getDiskConfig = arg:
    if arg == null || arg == { } then
      {
        type = "btrfs";
        impermanence = true;
        encrypted = false; # TODO: Implement encryption support in the future
        swapsize = "4G";
        device = "/dev/vda";
      }
    else if lib.isAttrs arg then
      {
        type = arg.type or "btrfs";
        impermanence = arg.impermanence or (arg.type or "btrfs" == "btrfs");
        encrypted = arg.encrypted or false; # TODO: Implement encryption support in the future
        swapsize = arg.swapsize or "4G";
        device = arg.device or "/dev/vda";
      }
    else
      throw "disk: argument must be an attribute set";

  # Get the appropriate filesystem aspect based on type
  getFilesystemAspect = config:
    if config.type == "btrfs" then
      (FTS.disk.btrfs {
        swapSize = config.swapsize;
        device = config.device;
        # TODO: Pass encrypted parameter when encryption support is implemented
      })
    else if config.type == "ext4" then
      (FTS.disk.ext4 {
        device = config.device;
        # TODO: Pass encrypted parameter when encryption support is implemented
      })
    else
      throw "disk: unsupported filesystem type '${config.type}'";

  # Configure swap based on swapsize - now handled by disko in filesystem modules
  configureSwap = config: nixos: nixos;

  # Configure impermanence if requested (filesystem-specific)
  configureImpermanence = config: nixos:
    if config.impermanence && config.type == "btrfs" then
      lib.mkMerge [
        {
          # Enable impermanence for Btrfs
          boot.initrd.postDeviceCommands = lib.mkBefore ''
            mkdir -p /mnt
            mount -o subvol=/ /dev/disk/by-label/nixos /mnt

            # Create snapshot if it doesn't exist
            if ! btrfs subvolume show /mnt/root-blank >/dev/null 2>&1; then
              btrfs subvolume snapshot /mnt/empty /mnt/root-blank 2>/dev/null || true
            fi

            # Delete and recreate root subvolume
            btrfs subvolume delete /mnt/root 2>/dev/null || true
            btrfs subvolume snapshot /mnt/root-blank /mnt/root 2>/dev/null || true
          '';
        }
        nixos
      ]
    else
      nixos;
in
{
  FTS.disk = den.lib.parametric {
    inherit description;
    includes = [
      ({ nixos, ... }: arg:
        let
          config = getDiskConfig arg;
          filesystemAspect = getFilesystemAspect config;
          # Extract the nixos module from the filesystem aspect
          filesystemModule = filesystemAspect.nixos or { };
        in
        lib.mkMerge [
          filesystemModule
          (configureSwap config nixos)
          (configureImpermanence config nixos)
        ]
      )
    ];
  };
}
