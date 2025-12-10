# Development shells configuration
{
  inputs,
  perSystem,
  ...
}:
{
  perSystem = { pkgs, system, ... }:
    let
      # Create a pkgs with unfree allowed for the deploy shell
      pkgsUnfree = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      # Default dev shell - general development tools
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          treefmt
          nixfmt-rfc-style
          shfmt
          nixd
          git
          just
          nh
          jq
          yq-go
          # Note: yq in nixpkgs is Python version, we need Go version for anchors
          # Using yq from nixpkgs (Python version) - will use manual editing fallback
          # SOPS tools for secrets management
          age
          sops
          ssh-to-age
          openssl
        ];
      };

      # Deploy shell - includes Terraform and deployment tools
      devShells.deploy = pkgsUnfree.mkShell {
        packages = with pkgsUnfree; [
          treefmt
          nixfmt-rfc-style
          shfmt
          nixd
          just
          nh
          sshpass
          (terraform.withPlugins (p: with p; [
            p.null
            p.external
          ]))
          jq
          yq-go  # Go version of yq (mikefarah/yq) for YAML editing with anchor support
          # SOPS tools for secrets management
          age
          sops
          ssh-to-age
          openssl
        ];
      };
    };
}

