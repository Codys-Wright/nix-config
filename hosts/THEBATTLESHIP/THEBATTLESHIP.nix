{
  inputs,
  fleet,
  __findFile,
  ...
}:
{
  den.hosts.x86_64-linux = {
    THEBATTLESHIP = {
      description = "The Main System, ready for everyday battle";
      users.cody = {
        extraGroups = [ "audio" ];
      };
      users.joshua = { };
      users.guest = { };
      users.bri = { };
      users.carter = { };
      aspect = "THEBATTLESHIP";
    };
  };

  den.aspects = {
    THEBATTLESHIP = {
      provides.to-users.includes = [ <fleet.desktop/home> ];

      includes = [
        <fleet/unfree>
        <fleet/fonts>
        <fleet/phoenix>
        <fleet/mactahoe>
        <fleet/stylix>
        <fleet.system/agent-user>

        (fleet.desktop { default = "niri"; })
        (fleet.grub { uefi = true; })

        (fleet.hardware {
          nvidia = true;
          tailscale = true;
        })

        <fleet/gaming>
        <fleet/apps>
        # controller-split bundles polkit + sudoers + InputPlumber config +
        # the launch-as / steam-as equivalents. Replaces the three modules
        # that used to live here (launch-as, inputplumber, coop-launcher).
        <fleet.gaming/controller-split>

        (<fleet.system/disk> {
          type = "btrfs-impermanence";
          device = "/dev/nvme2n1";
          withSwap = true;
          swapSize = "205";
          persistFolder = "/persist";
        })

        <fleet/kernel>

        # Music production base (Reaper, plugins, netaudio, environment).
        <fleet.music/production>

        # Dante / Inferno: this host is "THEBATTLESHIP" on the 10G Dante
        # network, bound to the enp12s0 NIC. Statime does PTP clock sync,
        # Inferno exposes a 128-channel virtual Dante soundcard.
        (fleet.music._.production._.statime {
          interface = "enp12s0";
          preferredLeader = "AA-4202524000109";
        })
        (fleet.music._.production._.inferno {
          bindIp = "10.10.10.10";
          deviceId = "00000A0A0A0A0001";
          channels = 128;
        })

        (fleet.selfhost._.samba-client { })
        <fleet.system/avahi>
        <fleet.system/virtualization>
        (fleet.deploy { ip = "100.74.250.99"; })

        # 10G network tuning for starcommand link
        # Static 10.10.10.10/24 — outside starcommand dnsmasq DHCP range (.100-.200),
        # gives Hermes/agent a stable address to SSH to from starcommand.
        (fleet.system._.network-10g {
          interface = "enp12s0";
          staticIp = "10.10.10.10/24";
        })
      ];

      nixos =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          # Studio routing channel map. One source of truth for both the
          # PipeWire loopback definitions and the studio-routing-links
          # systemd oneshot. Channel numbers reference the
          # THEBATTLESHIP.ReaperChanMap entries on Inferno TX/RX.
          # `fanout` (optional) is a list of additional Audio/Sink targets
          # that should also receive a copy of the sink's stereo signal,
          # wired from the loopback's capture-side `monitor_1/2` ports.
          # Used so e.g. System Audio plays *both* into the Dante TX
          # channels and out of the Yamaha TF console for local monitoring
          # without needing the Dante side to be wired up.
          yamahaTF = "alsa_output.usb-Yamaha_Corporation_Yamaha_TF-00.playback.0.0";
          studioRoutedSinks = [
            {
              name = "system_audio";
              desc = "System Audio";
              txL = 97;
              txR = 98;
              fanout = [
                {
                  node = yamahaTF;
                  portL = "playback_1";
                  portR = "playback_2";
                }
              ];
            }
            {
              name = "system_notifications";
              desc = "System Notifications";
              txL = 99;
              txR = 100;
              fanout = [ ];
            }
            {
              name = "voice_chat";
              desc = "Voice Chat";
              txL = 101;
              txR = 102;
              fanout = [ ];
            }
            # Games shares TX with System Audio but stays a separate
            # Audio/Sink so OBS / recordings can capture Games alone.
            {
              name = "games";
              desc = "Games";
              txL = 97;
              txR = 98;
              fanout = [ ];
            }
          ];
          studioRoutedSources = [
            {
              name = "talkback_mic";
              desc = "Talkback Mic";
              rxL = 51;
              rxR = 52;
            }
            {
              name = "talkback_mic_dsp";
              desc = "Talkback Mic [DSP]";
              rxL = 90;
              rxR = 91;
            }
          ];
        in
        {
          time.timeZone = "America/Los_Angeles";
          boot.loader.grub.configurationLimit = 15;

          # Prevent Intel I226-V (igc/enp11s0) PCIe link loss after extended uptime.
          # The I226-V has a hardware errata where the NIC self-initiates PCIe L1
          # substates independently of host ASPM, causing "PCIe link lost, device
          # now detached" after hours of uptime. pci=nommconf forces I/O port access
          # for PCI config space instead of MMIO, working around the link-drop bug.
          boot.kernelParams = [
            "pcie_aspm=off"
            "pci=nommconf"
          ];

          # Disable Energy Efficient Ethernet on the I226-V — EEE interaction with
          # the PCIe L1 substates errata is a common trigger for spontaneous link loss.
          systemd.services."igc-disable-eee" = {
            description = "Disable EEE on Intel I226-V (enp11s0) to prevent PCIe link drops";
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            wantedBy = [ "multi-user.target" ];
            script = "${pkgs.ethtool}/sbin/ethtool --set-eee enp11s0 eee off || true";
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
          };

          nix.gc = {
            automatic = true;
            dates = "weekly";
            options = "--delete-older-than 7d";
          };

          programs.nh.enable = true;

          # NTFS games partition
          fileSystems."/run/media/GAMES" = {
            device = "/dev/nvme2n1p2";
            fsType = "ntfs-3g";
            options = [
              "rw"
              "uid=1000"
            ];
          };

          # ext4 audio production partition
          fileSystems."/run/media/AudioHaven" = {
            device = "/dev/nvme0n1p2";
            fsType = "ext4";
            options = [
              "rw"
              "nofail"
            ];
          };

          # Mount starcommand storage over 10G NFS
          fileSystems."/mnt/starcommand" = {
            device = "10.10.10.1:/";
            fsType = "nfs";
            options = [
              "nfsvers=4.2"
              "rsize=1048576"
              "wsize=1048576"
              "_netdev"
              "noauto"
              "x-systemd.automount"
              "x-systemd.idle-timeout=600"
              "x-systemd.mount-timeout=30"
              "nofail"
              "soft"
              "timeo=150"
              "retrans=3"
            ];
          };

          programs.ssh.knownHosts."10.10.10.1" = {
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIENFHgs8JqCE4/dO58AN8W4M2SRgetgar94m2ntI9xb8";
          };

          # Hermes workspace on THEBATTLESHIP for remote SSH execution from starcommand.
          # The agent user lands in /home/cody/agent and gets symlinks to the source
          # trees it most commonly needs without having to bounce between shells.
          systemd.tmpfiles.rules = [
            "d /home/cody/agent 0755 cody users -"
            "L+ /home/cody/agent/.starcommand 0644 cody users - /home/cody/.starcommand"
            "L+ /home/cody/agent/.flake 0644 cody users - /home/cody/.flake"
          ];

          users.users.cody.openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFrMb6rGjMO0EzWfkG71kYnkbtxW5+oIUCyaum3uHViW agent@starcommand"
          ];
          # SOPS secrets
          imports = [ inputs.sops-nix.nixosModules.default ];
          sops = {
            defaultSopsFile = ../../users/cody/secrets.yaml;
            age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
            secrets."cody/proton/privatekey" = {
              owner = "root";
              group = "root";
              mode = "0400";
            };
          };

          # --- Virtual PipeWire routing nodes ---
          #
          # Every multichannel node (Inferno + the studio loopbacks) declares
          # plain numeric channels via `audio.position = ["UNK", …]`, so the
          # ports come out as `playback_N` / `capture_N` / `input_N` /
          # `output_N` instead of FL/FR/AUX… — easier to reason about and
          # required for explicit port-by-port linking by name. Specific
          # channel pairs are then wired by the `studio-routing-links`
          # systemd oneshot below using `pw-link`. WirePlumber 0.5 has no
          # static-link config, and PipeWire's `context.objects` link-
          # factory creation is fatal-on-missing-port at startup, so a
          # post-pipewire oneshot with retries is the reliable pattern.

          services.pipewire =
            let
              numericPos = n: lib.replicate n "UNK";

              # `node.autoconnect = false` tells WirePlumber's linking
              # policy to skip the node entirely; without it WP picks the
              # default sink as a target and grows the loopback's port
              # count to match (128). The link-factory pins are the only
              # things allowed to wire these ends.
              dontAutoconnect = {
                "node.autoconnect" = false;
                "node.dont-reconnect" = true;
              };
              mkRoutedSink =
                {
                  name,
                  desc,
                  txL,
                  txR,
                  fanout ? [ ],
                }:
                {
                  name = "libpipewire-module-loopback";
                  args = {
                    "node.description" = desc;
                    "capture.props" = {
                      "node.name" = name;
                      "node.description" = desc;
                      "media.class" = "Audio/Sink";
                      "audio.channels" = 2;
                      "audio.position" = numericPos 2;
                      "monitor.channel-volumes" = true;
                      "node.pause-on-idle" = false;
                    };
                    "playback.props" = dontAutoconnect // {
                      "node.name" = "${name}_to_inferno";
                      "node.description" = "${desc} → Inferno TX ${toString txL}/${toString txR}";
                      "audio.channels" = 2;
                      "audio.position" = numericPos 2;
                      "node.passive" = true;
                    };
                  };
                };
              mkRoutedSource =
                {
                  name,
                  desc,
                  rxL,
                  rxR,
                }:
                {
                  name = "libpipewire-module-loopback";
                  args = {
                    "node.description" = desc;
                    "capture.props" = dontAutoconnect // {
                      "node.name" = "${name}_from_inferno";
                      "node.description" = "Inferno RX ${toString rxL}/${toString rxR} → ${desc}";
                      "audio.channels" = 2;
                      "audio.position" = numericPos 2;
                      "node.passive" = true;
                    };
                    "playback.props" = {
                      "node.name" = name;
                      "node.description" = desc;
                      "media.class" = "Audio/Source";
                      "audio.channels" = 2;
                      "audio.position" = numericPos 2;
                      "node.passive" = true;
                    };
                  };
                };

              routedSinks = studioRoutedSinks;
              routedSources = studioRoutedSources;
            in
            {
              extraConfig.pipewire."93-studio-virtual-nodes" = {
                "context.modules" = [
                  # 128-ch DAW pass-through for Reaper. Linked 1:1 into
                  # Inferno sink by the link factories below.
                  {
                    name = "libpipewire-module-loopback";
                    args = {
                      "node.description" = "DAW";
                      "capture.props" = {
                        "node.name" = "daw";
                        "node.description" = "DAW";
                        "media.class" = "Audio/Sink";
                        "audio.channels" = 128;
                        "audio.position" = numericPos 128;
                        "node.pause-on-idle" = false;
                      };
                      "playback.props" = dontAutoconnect // {
                        "node.name" = "daw_to_inferno";
                        "audio.channels" = 128;
                        "audio.position" = numericPos 128;
                        "node.passive" = true;
                      };
                    };
                  }
                ]
                ++ map mkRoutedSink routedSinks
                ++ map mkRoutedSource routedSources;
              };

              wireplumber.extraConfig."80-pro-audio-usb"."monitor.alsa.rules" = [
                {
                  matches = [
                    { "device.name" = "alsa_card.usb-Yamaha_Corporation_Yamaha_TF-00"; }
                    { "device.name" = "~alsa_card.usb-Fractal_Audio.*"; }
                  ];
                  actions.update-props."api.alsa.use-acp" = false;
                }
              ];

              # Belt-and-suspenders: in case the per-loopback `node.autoconnect`
              # property doesn't make it through libpipewire-module-loopback's
              # adapter init, also pin the same flag from WirePlumber by name.
              wireplumber.extraConfig."95-studio-no-autolink"."node.rules" = [
                {
                  matches = [
                    { "node.name" = "~.*_to_inferno"; }
                    { "node.name" = "~.*_from_inferno"; }
                  ];
                  actions.update-props = {
                    "node.autoconnect" = false;
                    "node.dont-reconnect" = true;
                  };
                }
              ];
            };

          # --- Studio routing link service ---
          #
          # Walks every (out, in) port pair derived above and wires it via
          # `pw-link`. Idempotent: pw-link refuses to create a duplicate
          # link, and if a pair fails (because the node hasn't registered
          # yet) the loop retries until either both nodes exist or the
          # 60-second budget runs out.
          # WirePlumber persists "which profile is active for each card" in
          # ~pipewire/.local/state/wireplumber/default-profile. If a card's
          # entry says `off`, WP refuses to instantiate any sink/source for
          # it. We want the Yamaha TF console and the Ryzen onboard analog
          # to come up active on every boot, so seed those entries before
          # wireplumber starts. Cards we don't list (e.g. the Axe-Fx) keep
          # whatever the file previously had.
          systemd.services.wireplumber.serviceConfig.ExecStartPre =
            let
              seedScript = pkgs.writeShellScript "wireplumber-seed-profiles" ''
                set -u
                state=/var/lib/pipewire/.local/state/wireplumber/default-profile
                mkdir -p "$(dirname "$state")"
                touch "$state"

                # Each (card-name, profile) pair we want enforced.
                declare -A want=(
                  ["alsa_card.usb-Yamaha_Corporation_Yamaha_TF-00"]="on"
                  ["alsa_card.pci-0000_7a_00.6"]="output:analog-stereo+input:analog-stereo"
                )

                tmp=$(mktemp)
                # Keep the [default-profile] header and any keys we don't manage.
                if grep -q '^\[default-profile\]' "$state"; then
                  cp "$state" "$tmp"
                else
                  echo '[default-profile]' > "$tmp"
                fi

                for k in "''${!want[@]}"; do
                  v="''${want[$k]}"
                  if grep -qE "^$k=" "$tmp"; then
                    ${pkgs.gnused}/bin/sed -i "s|^$k=.*|$k=$v|" "$tmp"
                  else
                    echo "$k=$v" >> "$tmp"
                  fi
                done

                install -m 0644 "$tmp" "$state"
                rm -f "$tmp"
              '';
            in
            [ "${seedScript}" ];

          systemd.services.studio-routing-links =
            let
              sinkLinkPairs = builtins.concatMap (
                s:
                [
                  {
                    out = "${s.name}_to_inferno:output_1";
                    inp = "Inferno sink:playback_${toString s.txL}";
                  }
                  {
                    out = "${s.name}_to_inferno:output_2";
                    inp = "Inferno sink:playback_${toString s.txR}";
                  }
                ]
                ++ builtins.concatMap (f: [
                  {
                    out = "${s.name}:monitor_1";
                    inp = "${f.node}:${f.portL}";
                  }
                  {
                    out = "${s.name}:monitor_2";
                    inp = "${f.node}:${f.portR}";
                  }
                ]) (s.fanout or [ ])
              ) studioRoutedSinks;
              sourceLinkPairs = builtins.concatMap (s: [
                {
                  out = "Inferno source:capture_${toString s.rxL}";
                  inp = "${s.name}_from_inferno:input_1";
                }
                {
                  out = "Inferno source:capture_${toString s.rxR}";
                  inp = "${s.name}_from_inferno:input_2";
                }
              ]) studioRoutedSources;
              dawLinkPairs = lib.genList (i: {
                out = "daw_to_inferno:output_${toString (i + 1)}";
                inp = "Inferno sink:playback_${toString (i + 1)}";
              }) 128;
              allPairs = sinkLinkPairs ++ sourceLinkPairs ++ dawLinkPairs;
              pwLink = "${pkgs.pipewire}/bin/pw-link";
              pwCli = "${pkgs.pipewire}/bin/pw-cli";
              linkCmds = lib.concatMapStringsSep "\n" (p: ''try_link "${p.out}" "${p.inp}"'') allPairs;
              linkScript = pkgs.writeShellScript "studio-routing-links" ''
                set -u
                export PIPEWIRE_RUNTIME_DIR=/run/pipewire

                # Wait for Inferno sink/source to register. The ALSA plugin
                # has to spin up its Dante DeviceServer first, which can
                # take several seconds after pipewire start.
                for i in $(seq 1 60); do
                  if ${pwCli} ls Node 2>/dev/null \
                       | grep -q 'node.name = "Inferno sink"' \
                     && ${pwCli} ls Node 2>/dev/null \
                       | grep -q 'node.name = "Inferno source"' ; then
                    break
                  fi
                  sleep 1
                done

                # try_link: pw-link can fail if either port doesn't exist
                # yet (loopback node not registered, etc). Retry up to 10
                # times per pair before giving up. "exists" is success.
                try_link() {
                  local out="$1" inp="$2"
                  for j in $(seq 1 10); do
                    out_msg=$(${pwLink} "$out" "$inp" 2>&1) && return 0
                    case "$out_msg" in
                      *"exists"*|*"link exists"*) return 0 ;;
                    esac
                    sleep 1
                  done
                  echo "studio-routing-links: failed after retries: $out -> $inp ($out_msg)" >&2
                  return 1
                }

                ${linkCmds}
                exit 0
              '';
            in
            {
              description = "Wire studio loopback nodes to specific Inferno channel pairs";
              after = [ "pipewire.service" ];
              wants = [ "pipewire.service" ];
              wantedBy = [ "multi-user.target" ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                User = "pipewire";
                Group = "pipewire";
                ExecStart = linkScript;
              };
            };

          # --- Dante / Inferno audio network configuration ---

          # Disable systemd-timesyncd — it conflicts with statime-inferno PTP daemon
          services.timesyncd.enable = false;

          # Firewall rules for Dante audio network
          networking.firewall = {
            allowedUDPPorts = [
              319
              320
              4400
              4401
              8800
              4402
              4455
              5353
              8700
              8800
            ];
            # Dante allocates ephemeral receive ports dynamically, so we need
            # the full ephemeral range open on the Dante interface (enp12s0).
            # A more precise approach: trust the dedicated Dante interface.
            trustedInterfaces = [ "enp12s0" ];
          };
        };
    };
  };
}
