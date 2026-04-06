# CLI tools meta-aspect - includes all CLI tool modules
{
  fleet,
  ...
}:
{
  fleet.keyboard = {
    description = "Keyboard Configuration";

    includes = [
      fleet.kanata
      fleet.karabiner-elements
    ];

  };
}
