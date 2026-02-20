# Legacy compatibility provider.
# den built-ins now handle user/home dependency wiring in defaults.
{ den, ... }:
{
  den.aspects.dendritic.provides.routes = { ... }: { };
}
