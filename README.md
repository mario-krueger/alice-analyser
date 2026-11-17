# alice-analyser

An agent skill (for Claude and other coding agents) for working with ALICE analysers, and physicists in similar setups,
on their own machine. It makes the agent work like a careful scientific coworker:

- **structured:** a project notebook, a jointly developed step plan, fixed file conventions, a handover for the next session;
- **safe:** no damage to data or machine, protected zones, dry runs, Trash instead of delete, no silent or unrequested changes;
- **verified:** baselines, exact regression checks, predictions before running, checks that are proven to fail when they should;
- **reproducible:** determinism, provenance, results by recipe, saved states;
- **domain-aware:** O2Physics tasks, grid/AliEn and Hyperloop, ROOT-based offline corrections and unfolding, plotting,
  Python next to ROOT, and the usual technical pitfalls (macOS, zsh, ROOT/ACLiC, DPL, CI).

The skill is in [`alice-analyser/`](alice-analyser/SKILL.md). Start with `SKILL.md`; the `references/` are read on demand.

## Install

**Claude Code, for all your projects** (clone once, update with `git pull`):
```bash
git clone https://github.com/mario-krueger/alice-analyser.git ~/src/alice-analyser
mkdir -p ~/.claude/skills
ln -s ~/src/alice-analyser/alice-analyser ~/.claude/skills/alice-analyser
```

**Claude Code, for one project only:** copy (or symlink) the `alice-analyser/` folder into `<project>/.claude/skills/`.

**Claude apps (claude.ai, desktop):** download `alice-analyser.skill` from the
[latest release](https://github.com/mario-krueger/alice-analyser/releases/latest) and add it as a skill.

**Other agents:** point them to [`llms.txt`](llms.txt), or to `alice-analyser/SKILL.md` directly.

The skill triggers on its own when a request fits its description (an analysis project, data you did not create,
"don't break anything", "set up the project properly", …). You can also ask for it by name.

## What it contains

| path | content |
|---|---|
| `alice-analyser/SKILL.md` | the method: role, three analysis stages, rigour and momentum, what the agent may do without asking, reproducibility, step loop, safety, verification, project structure |
| `alice-analyser/references/` | details per topic: O2Physics, grid and Hyperloop, offline corrections, plotting, Python and ROOT, pitfalls, file conventions, collaboration, safety, verification, … |
| `alice-analyser/assets/` | templates: project notebook, CLAUDE.md, study README, dry-run plan script, `.gitignore` |
| `alice-analyser/scripts/` | `root_filecmp.C` (exact comparison of ROOT files), `check_tools.sh` (read-only environment report) |

## Status

Version 0.1.0 (see [CHANGELOG](CHANGELOG.md)). Tested with headless agents on sandboxed analysis scenarios
(cleanup, a requested change with a hidden trap, a newcomer, an unrelated bug, a new analysis from scratch, a macro
that would overwrite its input), with and without the skill. Feedback and issues are welcome.

## Development

- `scripts/check.sh` runs the repository checks (frontmatter, links, script syntax, privacy scan) and builds
  `dist/alice-analyser.skill`. CI runs the same on every push and attaches the `.skill` file to a release for each
  tag `v<version>` (the tag must match `VERSION`).
- One change per commit; update `CHANGELOG.md` and `VERSION` for each release.

License: [MIT](LICENSE).
