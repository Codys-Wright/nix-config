# Developer role aspect
{
  den,
  ...
}:
{
  den.aspects.developer = {
    description = "aspect for developer configurations";
    homeManager = { };
  };
  
  # adding a parametric aspect on a specific host/user/home.
  den.aspects.developer._.home.includes = [ den.aspects.example._.home ];
}

