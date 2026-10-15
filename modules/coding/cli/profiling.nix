# CPU profilers: perf (built for the running kernel) and samply (sampling
# profiler with the Firefox Profiler UI; `samply record <cmd>`).
{
  fleet.coding._.cli._.profiling = {
    description = "perf (matching the host kernel) + samply, with unprivileged perf events";

    provides.to-hosts.nixos =
      { config, pkgs, ... }:
      {
        environment.systemPackages = [
          config.boot.kernelPackages.perf
          pkgs.samply
        ];
        # Let a user profile their own processes (perf record/top, samply)
        # without root: 1 = user-space + kernel samples of own processes only.
        # The NixOS default (2) blocks samply and most `perf record` uses.
        boot.kernel.sysctl."kernel.perf_event_paranoid" = 1;
      };

    provides.to-hosts.darwin =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.samply ];
      };
  };
}
