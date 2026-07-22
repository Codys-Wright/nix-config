{ den, ... }:
{
  den.aspects.THEBATTLESHIP-audio-latency = {
    description = "RT kernel, DMA/IRQ latency pinning, and NIC/USB quirk workarounds for low-latency audio";
    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        # Prevent Intel I226-V (igc/enp11s0) PCIe link loss after extended uptime.
        # The I226-V has a hardware errata where the NIC self-initiates PCIe L1
        # substates independently of host ASPM, causing "PCIe link lost, device
        # now detached" after hours of uptime. pci=nommconf forces I/O port access
        # for PCI config space instead of MMIO, working around the link-drop bug.
        boot.kernelParams = [
          "pcie_aspm=off"
          "pci=nommconf"
          # Never auto-suspend USB — the TF audio interface must not be
          # power-managed mid-session.
          "usbcore.autosuspend=-1"
        ];

        # ── Low-latency audio (user-level PipeWire) ──────────────────────────
        # PREEMPT_RT real-time kernel on mainline 6.18 (CONFIG_PREEMPT_RT).
        # Cuts worst-case scheduling jitter (~500 µs generic → <100 µs RT) — the
        # real limiter on minimum audio buffer size. Build-tested: Nvidia 595.x
        # compiles against it. PREEMPT_DYNAMIC off (mutually exclusive with RT).
        boot.kernelPackages = lib.mkForce (
          pkgs.linuxPackagesFor (
            pkgs.linux_6_18.override {
              structuredExtraConfig = with lib.kernel; {
                PREEMPT_RT = yes;
                PREEMPT_DYNAMIC = lib.mkForce no;
              };
              ignoreConfigErrors = true;
            }
          )
        );

        # Keep all cores at max clock. The kernel default `powersave` governor
        # lets cores drop into low P-states, adding DVFS ramp-up latency and
        # frequency jitter to the audio path. musnix doesn't set a governor and
        # the rt-isolation aspect that used to pin `performance` is currently
        # disabled on this host, so pin it here. This is the governor Millisecond
        # flags as the main remaining low-latency bottleneck. Applies on activate
        # (no reboot); a plugged-in studio box has no reason to downclock.
        powerManagement.cpuFreqGovernor = "performance";

        # Hold CPU PM-QoS DMA latency at 0 — disables the deep C-states that add
        # CPU wakeup jitter (AMD's are aggressive). The wakeup-latency half of
        # the jitter floor; the RT kernel is the other half.
        systemd.services.cpu-dma-latency = {
          description = "Pin cpu_dma_latency to 0 (no deep C-states) for low audio jitter";
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "simple";
            Restart = "always";
            ExecStart = ''${pkgs.python3}/bin/python3 -c "import os,struct,signal; fd=os.open('/dev/cpu_dma_latency', os.O_WRONLY); os.write(fd, struct.pack('i', 0)); signal.pause()"'';
          };
        };

        # Raise RT priority of the threaded xHCI USB IRQ handlers so the TF's USB
        # completions aren't preempted (threadirqs makes these kernel threads).
        systemd.services.audio-usb-irq-prio = {
          description = "Bump xHCI USB IRQ threads to RT priority for audio";
          wantedBy = [ "multi-user.target" ];
          after = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            for pid in $(${pkgs.procps}/bin/ps -eLo pid=,comm= \
                | ${pkgs.gnugrep}/bin/grep -E 'irq/[0-9]+-xhci' \
                | ${pkgs.gawk}/bin/awk '{print $1}'); do
              ${pkgs.util-linux}/bin/chrt -f -p 85 "$pid" 2>/dev/null || true
            done
          '';
        };

        # Disable Energy Efficient Ethernet on the I226-V — EEE interaction
        # with PCIe L1 substates errata triggers spontaneous link loss.
        # The boot-time oneshot below covers the initial bring-up, and the
        # udev rule re-applies EEE=off every time the kernel binds the
        # interface (after a PCIe rescan, suspend/resume, or NM bouncing
        # the link), since NetworkManager has been observed to re-enable EEE
        # on its own activations.
        systemd.services."igc-disable-eee" = {
          description = "Disable EEE on Intel I226-V (enp11s0) to prevent PCIe link drops";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];
          script = "${pkgs.ethtool}/bin/ethtool --set-eee enp11s0 eee off || true";
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
        };

        services.udev.extraRules = ''
          # Re-disable EEE every time the igc driver binds an I226-V (vendor
          # 8086, device 125c). Matches on add+change so it fires after PCIe
          # rescans and NetworkManager link cycles.
          ACTION=="add|change", SUBSYSTEM=="net", DRIVERS=="igc", ATTRS{vendor}=="0x8086", ATTRS{device}=="0x125c", RUN+="${pkgs.ethtool}/bin/ethtool --set-eee %k eee off"

          # Keychron K2 HE registers a HID joystick interface that claims js0,
          # bumping real gamepads to controller 2 in Steam. Strip joystick from
          # its input class so it stays a keyboard/mouse only.
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="3434", ATTRS{idProduct}=="0e20", ENV{ID_INPUT_JOYSTICK}="", ENV{ID_INPUT_KEY}="1"
        '';

        # ethtool is added alongside iw/tcpdump/etc in the dedicated
        # environment.systemPackages block lower in this file (search for
        # "ethtool" there). Keep that single definition to avoid a second
        # mergeable assignment in the same module.
      };
  };
}
