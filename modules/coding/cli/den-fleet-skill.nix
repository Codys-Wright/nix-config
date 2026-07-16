# den-fleet agent skill — teaches Claude Code the canonical way to install,
# package, and configure software in this repo. The skill text is tracked in
# skills/den-fleet/SKILL.md and installed declaratively like the herdr/hunk
# upstream skills, so every machine's agent gets the same conventions.
{
  fleet,
  ...
}:
{
  fleet.coding._.cli._.den-fleet-skill = {
    description = "Installs the den-fleet Claude Code skill (repo conventions for installing software)";

    homeManager = {
      home.file.".claude/skills/den-fleet/SKILL.md".source = ../../../skills/den-fleet/SKILL.md;
    };
  };
}
