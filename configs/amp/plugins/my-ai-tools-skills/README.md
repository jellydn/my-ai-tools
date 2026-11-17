# my-ai-tools Amp skills plugin

This directory plugin bundles every skill from the repository's canonical [`skills/`](../../../../skills/) directory.
Amp registers each skill under the qualified name `my-ai-tools-skills:<skill-name>`; for example,
`my-ai-tools-skills:code-review`.

## Install from this repository

Run the repository installer (always preview it first):

```bash
./cli.sh --dry-run
./cli.sh
```

The installer copies this directory to `~/.config/amp/plugins/my-ai-tools-skills/`. This is a machine-local installation.

## Publish as a personal plugin

To make the plugin available in every Amp environment, copy this entire `my-ai-tools-skills/` directory to the root of
your Amp User Plugins repository, commit it there, and push it. Publishing requires that final push; this source
repository does not publish the plugin automatically.

After publishing, reload Amp plugins and verify a bundled skill:

```bash
amp skill info my-ai-tools-skills:code-review
amp skill info my-ai-tools-skills:accountable-engineering
```

## Keeping the bundle synchronized

The canonical source remains the repository's top-level `skills/` directory. When adding or changing a skill, mirror
the complete skill directory here. `tests/pr_amp_skills_plugin.bats` verifies that the inventory and every bundled file
remain identical.
