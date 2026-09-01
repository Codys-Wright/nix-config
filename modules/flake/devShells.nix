# Development shells configuration
{
  inputs,
  perSystem,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    {
      # Default dev shell - general development tools
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          treefmt
          nixfmt
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
      devShells.deploy = pkgs.mkShell {
        packages = with pkgs; [
          treefmt
          nixfmt
          shfmt
          nixd
          just
          nh
          sshpass
          # nixpkgs 26.11 renamed terraform-providers to namespaced attrs
          # (`null` → `hashicorp_null`, `external` → `hashicorp_external`).
          (terraform.withPlugins (p: [
            p.hashicorp_null
            p.hashicorp_external
          ]))
          jq
          yq-go # Go version of yq (mikefarah/yq) for YAML editing with anchor support
          # SOPS tools for secrets management
          age
          sops
          ssh-to-age
          openssl
        ];
      };
    };
}
