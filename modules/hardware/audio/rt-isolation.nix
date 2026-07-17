# Real-time CPU core isolation for deterministic audio (Dante/Inferno + other
# RT work). Walls a set of cores off from the general scheduler so a pegged
# system (games, compiles, browser) can NEVER preempt the audio threads — the
# difference between "no xruns on an idle box" and "no xruns, period".
#
# Parametric aspect. Pass the logical CPUs to dedicate (include BOTH SMT
# siblings of each physical core so nothing general runs on the sibling and
# pollutes the core), the total CPU count, the Dante NIC, and which
# housekeeping CPUs should service its IRQs:
#
#   (fleet.hardware._.audio._.rt-isolation {
#     cores      = [ 13 14 15 29 30 31 ];  # CCD1 cores 13-15 + SMT siblings
#     totalCpus  = 32;
#     nic        = "enp12s0";
#     nicIrqCpus = "8-11";                 # Dante NIC IRQs near (not on) audio cores
#   })
#
# What it does:
#   - isolcpus/nohz_full/rcu_nocbs on the dedicated cores (kernel params →
#     needs a reboot). Only tasks explicitly pinned there (the audio stack)
#     run on them; the kernel keeps timer ticks, RCU callbacks and general
#     threads off.
#   - Default IRQ affinity + the Dante NIC's IRQs steered to housekeeping
#     cores, so packet interrupts never steal cycles from the RT thread
#     (the socket buffers decouple NIC ingest from the audio cores).
#   - Holds /dev/cpu_dma_latency at 0 to cap C-state exit latency — deep idle
#     wakeups are a major source of RT jitter.
#   - Performance governor so the audio cores never downclock.
#
# The PipeWire side (pinning the per-user pipewire to these cores via
# CPUAffinity) lives in the user's home aspect — see
# users/cody/modules/pipewire.nix — because den routes host aspects to nixos
# only. The two must agree on the core list.
{ fleet, lib, ... }:
{
  fleet.hardware._.audio._.rt-isolation.description =
    "Dedicated RT CPU cores for deterministic Dante/audio (isolcpus + IRQ steering + C-state cap)";

  fleet.hardware._.audio._.rt-isolation.__functor =
    _self:
    {
      cores,
      totalCpus,
      nic ? null,
      nicIrqCpus ? null,
      governor ? "performance",
      ...
    }:
    let
      isolatedList = lib.concatMapStringsSep "," toString cores;
      allCpus = lib.range 0 (totalCpus - 1);
      housekeeping = lib.subtractLists cores allCpus;
      housekeepingList = lib.concatMapStringsSep "," toString housekeeping;
    in
    {
      nixos =
        { pkgs, lib, ... }:
        {
          boot.kernelParams = [
            # Remove the audio cores from the general scheduler + tickless +
            # offload RCU callbacks. `managed_irq` keeps driver-managed IRQs
            # off them; `domain` isolates scheduling domains.
            "isolcpus=domain,managed_irq,${isolatedList}"
            "nohz_full=${isolatedList}"
            "rcu_nocbs=${isolatedList}"
            # Default IRQ affinity → housekeeping cores only.
            "irqaffinity=${housekeepingList}"
          ];

          # Never downclock — consistent frequency on the audio cores. Plugged-
          # in studio/desktop box, so global performance is the simple choice.
          powerManagement.cpuFreqGovernor = lib.mkDefault governor;

          # Hold the PM-QoS cpu_dma_latency at 0 so cores can't drop into deep
          # C-states with long exit latency (pure RT jitter). The constraint is
          # active only while the fd is held open, so the process must persist.
          systemd.services.rt-cpu-dma-latency = {
            description = "Cap CPU DMA latency (C-state exit) at 0 for RT audio";
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "simple";
              ExecStart =
                "${pkgs.python3}/bin/python3 -c "
                + "\"import struct,signal;"
                + "f=open('/dev/cpu_dma_latency','wb');"
                + "f.write(struct.pack('i',0));f.flush();signal.pause()\"";
              Restart = "on-failure";
            };
          };

          # Steer the Dante NIC's IRQs onto dedicated housekeeping cores (near
          # the audio cores for cache locality, but not ON them). Re-applied on
          # a timer because the driver can re-balance after link events.
          systemd.services.rt-nic-irq-affinity = lib.mkIf (nic != null && nicIrqCpus != null) {
            description = "Pin ${nic} IRQs to housekeeping cores ${nicIrqCpus}";
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = pkgs.writeShellScript "rt-nic-irq-affinity" ''
                set -u
                changed=0
                for irq in $(${pkgs.gnugrep}/bin/grep "${nic}" /proc/interrupts | cut -d: -f1 | tr -d ' '); do
                  if echo "${nicIrqCpus}" > "/proc/irq/$irq/smp_affinity_list" 2>/dev/null; then
                    changed=$((changed+1))
                  fi
                done
                echo "pinned $changed ${nic} IRQs to CPUs ${nicIrqCpus}"
              '';
            };
          };
          systemd.timers.rt-nic-irq-affinity = lib.mkIf (nic != null && nicIrqCpus != null) {
            description = "Re-assert ${nic} IRQ affinity periodically";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnBootSec = "1min";
              OnUnitActiveSec = "10min";
            };
          };
        };
    };
}
