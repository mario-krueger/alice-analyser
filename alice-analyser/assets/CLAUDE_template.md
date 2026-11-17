# Working rules for this project

Read these first. They come from the project owner and override defaults.

**Session start:** before the first action, read `docs/PROJECT.md` §0 (current state), then §1b (roadmap), §2 (status), §5 (decisions).
New findings/decisions go there, dated. Don't let them live only in chat.

## Folders: what goes where
- **git (umbrella):** tools only: `bin/`, `config/`, `tests/`, `env.sh`, README. Commits only with the owner's yes.
- **`docs/`** (local): notebook, topic notes, PR texts, executed plan scripts.
- **`share/`** (local): the owner's material for the agent. **Read only.**
- **`workbench/<date>_<topic>/`** (local): disposable studies. Result into the notebook before a study may be deleted.
- Sub-repos inside the umbrella, each its own git repo: `<name>/` (<what>).

## Zones (agreed <date>)
| zone | paths | agent may |
|---|---|---|
| user-only | <paths> | never write (read only where allowed) |
| protected inputs | <paths> | read/copy only |
| tracked work (git) | <repos/folders> | change via proposal → yes → check; commits only with a yes |
| agent playground (git-ignored) | `workbench/`, `runs/`, `datasets/dev/`, `input/`, scratch | create, test, small downloads within the disk budget (size stated), delete own files |

## Data safety (most important)
- **`<path>` is read-only** (<why: irreplaceable / published / someone else's>). Never write, rename, delete or create
  anything there; no tools whose outputs land next to their inputs pointed there. For studies, copy into the study
  folder and make the copies read-only.
- Our outputs go to `runs/` and `datasets/dev/` (the tools refuse protected targets).
- Moves/deletions: dry run first, to the Trash or a dated holding folder; the owner empties it.

## Working style
- Patient, in a good order, one topic per step; no bundling of unrelated changes.
- Every step verified: reproducibility (bit-identical where possible), before/after comparisons, only the expected
  effect happened. Checks come with quick plots where a picture helps.
- Every step understandable: explain what changes and why; evidence instead of claims; flag uncertainties.
- Small surgical diffs: only lines that trace to the request; mention unrelated issues instead of fixing them in passing.

## Ask before acting
- No git actions without an explicit yes (init, commit, branch, push, tag), in any repo. "I'm thinking about X" is not a yes.
- <Code that changes results>: review and discuss first, change after agreement.
- Restructuring: one step at a time: proposal (+ dry run) → approval → execute → checks → report.
- Actions with the owner's identity (grid, web, CI): read freely; every state-changing action needs its own yes.
- Never type passwords; start the command and let the owner type.

## Code and repos
- **<repo>**: <rules: reproducibility requirement, regression test to run after every change, linters/CI parity>.
- Comments brief, in the existing style; keep the owner's comments verbatim in refactors.

## Environment
- Shell: <zsh/bash>; macOS BSD tools (`sed -i ''`); loops over argument lists in bash scripts.
- Entry points: `bin/<...>`.
