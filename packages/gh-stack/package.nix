# gh-stack — GitHub's official CLI extension for native stacked PRs
# (github/gh-stack), on the release the fleet wants rather than nixpkgs'
# (0.1.1 when this was written). Exposed as pkgs.fleet-gh-stack (the name
# collides with nixpkgs). Drop this package once nixpkgs reaches the same
# version.
#
# The agent skill upstream ships (skills/gh-stack: SKILL.md + references)
# is installed to share/skills/gh-stack, copied by hand: nixpkgs'
# installAgentSkills hook also runs in the go-modules derivation, where
# $pname is unset, and fails it.
{
  lib,
  buildGoModule,
  fetchFromGitHub,
  gitMinimal,
}:

buildGoModule (finalAttrs: {
  pname = "gh-stack";
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "github";
    repo = "gh-stack";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Mq4jAqeSHDuCiDYSa40okrq06UhC3dZGjgCXJKMbgzU=";
  };

  vendorHash = "sha256-TC1mSXYjOQo00fb2yuGdk1rl6z6rp0WT3AmzXomPzis=";

  ldflags = [
    "-s"
    "-X=github.com/github/gh-stack/cmd.Version=${finalAttrs.version}"
  ];

  nativeCheckInputs = [ gitMinimal ];
  # v0.2.1's interactive `modify` view: the insert-mode model tests
  # (internal/tui/modifyview, every name has "Insert") fail in the build
  # sandbox; the CLI's own packages (cmd, stack, git, modify) pass.
  checkFlags = [ "-skip=Insert" ];

  postInstall = ''
    mkdir -p $out/share/skills
    cp -r skills/gh-stack $out/share/skills/gh-stack
  '';

  meta = {
    description = "GitHub CLI extension to use stacked PRs";
    homepage = "https://github.github.com/gh-stack/";
    license = lib.licenses.mit;
    mainProgram = "gh-stack";
    platforms = lib.platforms.unix;
  };
})
