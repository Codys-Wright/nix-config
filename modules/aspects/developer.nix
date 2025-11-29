# Developer role aspect
{
  den,
  FTS,
  ...
}:
{
  FTS.developer = {
    description = "aspect for developer configurations";
    homeManager = { };
  };
  
  # adding a parametric aspect on a specific host/user/home.
  FTS.developer._.home.includes = [ FTS.example._.home ];
}

