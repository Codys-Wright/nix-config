# SSH client configuration - host aliases and peer-reachability tiers
{ ... }:
{
  cody.ssh.homeManager =
    { ... }:
    {
      # SSH host aliases for easy access to deployed machines
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks = {
          "*" = {
            forwardAgent = false;
            addKeysToAgent = "no";
            compression = false;
            serverAliveInterval = 0;
            serverAliveCountMax = 3;
            hashKnownHosts = false;
            userKnownHostsFile = "~/.ssh/known_hosts";
            controlMaster = "no";
            controlPath = "~/.ssh/master-%r@%n:%p";
            controlPersist = "no";
          };
          "starcommand" = {
            hostname = "10.10.10.1";
            user = "starcommand";
            identityFile = "~/.ssh/id_ed25519";
          };
          "starcommand-root" = {
            host = "starcommand-root";
            hostname = "10.10.10.1";
            user = "root";
            identityFile = "~/.ssh/id_ed25519";
          };
          # Task server tunnels — the auth-independent escape hatch:
          # as long as root SSH to starcommand works, the task CLI can
          # reach either environment regardless of TLS/ingress/auth
          # state. `ssh -f -N task-prod-tunnel` then point the CLI at
          # ws://127.0.0.1:18098/vox (dev: 18099). Targets are k8s
          # Service ClusterIPs — stable until the Service is recreated
          # (refresh: kubectl get svc task-server -n task).
          "task-prod-tunnel" = {
            hostname = "10.10.10.1";
            user = "root";
            identityFile = "~/.ssh/id_ed25519";
            localForwards = [
              {
                bind.port = 18098;
                host.address = "10.43.152.234";
                host.port = 80;
              }
            ];
            extraOptions = {
              ExitOnForwardFailure = "yes";
              ServerAliveInterval = "30";
            };
          };
          "task-dev-tunnel" = {
            hostname = "10.10.10.1";
            user = "root";
            identityFile = "~/.ssh/id_ed25519";
            localForwards = [
              {
                bind.port = 18099;
                host.address = "10.43.93.81";
                host.port = 80;
              }
            ];
            extraOptions = {
              ExitOnForwardFailure = "yes";
              ServerAliveInterval = "30";
            };
          };
          # THEBATTLESHIP <-> voyager peer reachability (10G LAN / home LAN /
          # Tailscale) is handled by the Match-exec tiers in extraConfig below,
          # so no static THEBATTLESHIP host block here.
          "electric" = {
            hostname = "100.65.190.11";
            user = "root";
          };
          # Forgejo git access. Forgejo now runs in the k3s cluster
          # (rootless image): SSH login user is `git`, git SSH on port 2222
          # (host :22 stays the admin sshd; a socat forward bridges :2222 ->
          # the forgejo SSH NodePort). Forgejo maps the key to the account,
          # so cody's key authenticates as codywright.
          "git.starcommand.live" = {
            hostname = "git.starcommand.live";
            user = "git";
            port = 2222;
            identityFile = "~/.ssh/id_ed25519";
          };
        };

        # Peer reachability between THEBATTLESHIP and voyager, in priority
        # order: 10G hardwired (10.10) -> home LAN (192) -> Tailscale
        # MagicDNS (works across networks). Each Match-exec probes a port
        # with a 1s timeout; the first reachable tier sets HostName (ssh
        # uses the first value it sees), otherwise it falls through to the
        # Tailscale FQDN. `nc` is /usr/bin/nc on macOS and in PATH on NixOS.
        extraConfig = ''
          Match host voyager exec "nc -z -w1 10.10.10.186 22 2>/dev/null"
            HostName 10.10.10.186
          Match host voyager exec "nc -z -w1 192.168.0.132 22 2>/dev/null"
            HostName 192.168.0.132
          Host voyager
            HostName voyager.tail666c4b.ts.net
            User cody
            IdentityFile ~/.ssh/id_ed25519

          Match host thebattleship,THEBATTLESHIP,thebattleship-1 exec "nc -z -w1 10.10.10.10 22 2>/dev/null"
            HostName 10.10.10.10
          Match host thebattleship,THEBATTLESHIP,thebattleship-1 exec "nc -z -w1 192.168.0.33 22 2>/dev/null"
            HostName 192.168.0.33
          Host thebattleship THEBATTLESHIP thebattleship-1
            HostName thebattleship.tail666c4b.ts.net
            User cody
            IdentityFile ~/.ssh/id_ed25519
        '';
      };
    };
}
