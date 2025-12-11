# Desktop environment facet - Provides access to different desktop environments
{
  FTS,
  ...
}:
{
  FTS.desktop._.environment.description = ''
    Desktop environment configuration with support for multiple DEs.
    
    Usage as router:
      (<FTS/desktop/environment> { default = "hyprland"; includes = ["gnome" "kde"]; })
    
    Direct access to specific environments:
      (<FTS/desktop/environment/gnome> { })
      (<FTS/desktop/environment/hyprland> { })
      (<FTS/desktop/environment/kde> { })
  '';

  # Make environment callable as a router function
  FTS.desktop._.environment.__functor =
    _self:
    {
      default ? null,
      includes ? [],
      ...
    }@args:
    { class, aspect-chain }:
    let
      # Available desktop environments
      availableEnvs = ["gnome" "hyprland" "kde" "xfce"];
      
      # Validate default
      validDefault = if default != null && !(builtins.elem default availableEnvs)
        then throw "desktop.environment: unknown default '${default}'. Available: ${builtins.concatStringsSep ", " availableEnvs}"
        else default;
      
      # Validate includes
      invalidIncludes = builtins.filter (e: !(builtins.elem e availableEnvs)) includes;
      _ = if invalidIncludes != []
        then throw "desktop.environment: unknown environments in includes: ${builtins.concatStringsSep ", " invalidIncludes}"
        else null;
      
      # Get the environment provider
      getEnv = name: FTS.desktop._.environment._.${name};
      
      # Build includes list
      envIncludes = map getEnv (
        if default != null && includes == [] then [default]
        else if includes != [] then includes
        else throw "desktop.environment: must specify either 'default' or 'includes'"
      );
    in
    {
      includes = envIncludes;
    };
}

