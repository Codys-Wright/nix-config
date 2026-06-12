# Single owner of shared namespaces, so the many apps living in `selfhost`
# don't each declare the Namespace (which made Argo show it perpetually
# OutOfSync across all of them).
{ ... }:
{
  applications.namespaces = {
    namespace = "selfhost";
    createNamespace = true;
    # nothing else — this app exists only to own the namespace.
    resources = { };
  };
}
