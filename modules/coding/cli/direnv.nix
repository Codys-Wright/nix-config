# Direnv - better than native direnv nix functionality
{
  fleet.coding._.cli._.direnv = {
    description = "Direnv for automatic environment loading";

    homeManager =
      { pkgs, ... }:
      {
        programs.direnv = {
          enable = true;
          enableBashIntegration = true;
          enableZshIntegration = true;
          enableNushellIntegration = true;
          nix-direnv.enable = true;
          # Agent worktrees come and go; trust every .envrc under the dev
          # drives instead of a `direnv allow` per checkout.
          config.whitelist.prefix = [
            "/run/media/Development"
            "/Volumes/build-disk/development"
          ];
        };

        # The repos' dev environments are devenv (`use devenv` in .envrc).
        home.packages = [ pkgs.devenv ];

        # direnv's own zsh hook fires on the prompt, which a non-interactive
        # zsh (an agent's command, `ssh host zsh -lc …`) never shows. There,
        # load the directory's environment when the shell starts and on every
        # `cd`, quietly, so commands run inside the project's dev shell.
        programs.zsh.envExtra = ''
          if [[ ! -o interactive ]] && (( $+commands[direnv] )); then
            export DIRENV_LOG_FORMAT=""
            _direnv_noninteractive() { eval "$(direnv export zsh 2>/dev/null)"; }
            typeset -ag chpwd_functions
            chpwd_functions+=(_direnv_noninteractive)
            _direnv_noninteractive
          fi
        '';
      };
  };
}
