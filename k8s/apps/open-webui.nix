# open-webui — first real selfhostblocks→cluster migration.
#
# Host-side counterpart (Authelia OIDC client, oauth k8s Secret, Ollama
# exposure, tunnel ingress chat.starcommand.live -> NodePort 30081) lives in
# starcommand's <FTS.cluster/open-webui-bridge>.
{ charts, ... }:
{
  applications.open-webui = {
    namespace = "ai";
    createNamespace = true;

    helm.releases.open-webui = {
      chart = charts.open-webui.open-webui;
      values = {
        # Ollama stays a NixOS service on starcommand (GPU there today;
        # opportunistic GPU jobs on THEBATTLESHIP are phase 3).
        ollama.enabled = false;
        pipelines.enabled = false;
        ollamaUrls = [ "http://10.10.10.1:11434" ];

        service = {
          type = "NodePort";
          nodePort = 30081;
        };

        persistence = {
          enabled = true;
          storageClass = "nas-nfs";
          accessModes = [ "ReadWriteMany" ];
          size = "10Gi";
        };

        extraEnvVars = [
          {
            name = "WEBUI_URL";
            value = "https://chat.starcommand.live";
          }
          {
            name = "ENABLE_OAUTH_SIGNUP";
            value = "true";
          }
          {
            name = "OAUTH_MERGE_ACCOUNTS_BY_EMAIL";
            value = "true";
          }
          {
            name = "OAUTH_CLIENT_ID";
            value = "open-webui";
          }
          {
            name = "OAUTH_PROVIDER_NAME";
            value = "Authelia";
          }
          {
            name = "OPENID_PROVIDER_URL";
            value = "https://auth.starcommand.live/.well-known/openid-configuration";
          }
          {
            name = "OAUTH_SCOPES";
            value = "openid email profile groups";
          }
          {
            name = "OAUTH_CLIENT_SECRET";
            valueFrom.secretKeyRef = {
              name = "open-webui-oauth";
              key = "client-secret";
            };
          }
        ];
      };
    };
  };
}
