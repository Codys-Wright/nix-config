# Languages facet - All programming language toolchains
{
  FTS,
  ...
}:
{
  FTS.coding._.lang = {
    description = "All programming language toolchains - rust, typescript";
    
    includes = [
      FTS.coding._.lang._.rust
      FTS.coding._.lang._.typescript
    ];
  };
}

