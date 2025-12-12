# Notes facet - All note-taking applications
{
  FTS,
  ...
}:
{
  FTS.apps._.notes = {
    description = "All note-taking applications - obsidian";
    
    includes = [
      FTS.apps._.notes._.obsidian
    ];
  };
}

