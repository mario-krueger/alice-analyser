# Project structure: a workable environment

Goal: a new session (or a new person) can pick up the work in minutes, every result can be traced to the code and input
that made it, and disposable work never mixes with durable tools or precious data.

## Contents
1. First session in a new project
2. The umbrella layout and what goes where
3. The notebook (`docs/PROJECT.md`)
4. CLAUDE.md and memory
5. Study folders (`workbench/`)
6. Tools (`bin/`), runs and provenance
7. Restructuring an existing project

---

## 1. First session in a new project

Read before acting. A good first session produces understanding and a proposal, not changes.

0. Run `bash scripts/check_tools.sh` (read only) and ask the user to install what the task needs (`toolbox.md`);
   confirm the O2Physics checkout, build dir and alienv package it found.
1. Read the README(s), the build system, the entry points, and any existing notes. Map the repos, where data lives,
   what is generated vs irreplaceable.
2. Ask the owner (batch the questions, each with a recommendation):
   - which folders/files are **read-only** (data, archives, frozen documents, other people's code);
   - which **results must stay reproducible** (published numbers, references others use);
   - their **working style** (how much autonomy, git rules, commenting style, language);
   - goals and horizons (soon / next / ongoing).
3. Agree the **zone map** (user-only, protected inputs, tracked work, agent playground; SKILL.md §3) and write CLAUDE.md (rules, zones) and start the notebook (state, goals, open questions). Use `assets/CLAUDE_template.md`
   and `assets/PROJECT_template.md`.
4. If the user wants help structuring the analysis itself (chain, tests, git): `analysis-design.md`.
5. Propose a roadmap: an ordered list of steps, one topic each, each with its check. Safety nets (regression tests)
   come **first**, before the changes they protect.

## 2. The umbrella layout and what goes where

One folder ("umbrella") is the entry point. It holds the glue (scripts that know about the local environment) and
contains the other repos as subfolders, each its own git repo, ignored by the umbrella.

| folder | content | git | rule |
|---|---|---|---|
| `bin/` | entry-point scripts, each with `-h` | tracked | refuse dangerous targets; record provenance |
| `config/` | run configurations | tracked | generated configs come with their generator |
| `tests/` | regression scripts, comparators | tracked (references local) | references are replaced only deliberately, with a notebook note |
| `env.sh` | paths, environment, protected dirs | tracked | the single place for absolute paths |
| `docs/` | notebook, topic notes, PR texts, executed plan scripts | local (private) | dated entries; plan scripts stay as executed |
| `share/` | the owner's material for the agent | local | **read only for the agent** |
| `workbench/<date>_<topic>/` | studies | local | disposable after the result is in the notebook |
| `runs/` | one folder per run | local | never edited after the fact |
| `datasets/dev/` | our derived datasets | local | never next to protected inputs |
| `<subrepo>/` | other repos | own git | changes follow that repo's rules |

**Zones on top of the table:** `share/`, the protected data and everything outside the project are user-only or
read-only; `bin/ config/ tests/` and the sub-repos are tracked work (step loop + git); `workbench/ runs/ datasets/dev/
input/` (git-ignored) are the agent's playground. Write this map into CLAUDE.md so the user knows their safe spaces.

Why this split: tools are small, shareable and versioned; studies are many, messy and temporary; data is big and
precious. Mixing them is how references get overwritten and junk gets committed.

Practical lessons:
- **Generic logic belongs in the generic tool** (framework, library); environment-specific glue (grid, local paths,
  particular datasets) belongs in the umbrella.
- **Single-purpose links** (`o2physics/checkout`, `o2physics/build`) are clearer than a top-level `build` that could
  mean any of three repos.
- **macOS file systems are usually case-insensitive**: `o2physics` and `O2Physics` are the same name. Check before naming.
- **Absolute paths break on every move**: keep them in `env.sh`; expect build caches (CMake, ACLiC `.so`, IDE projects)
  to need a rebuild after moving a folder.
- **Naming scheme decided once, applied everywhere** (e.g. datasets `<system>_<√s in GeV>`; no `.` in names; reserve
  characters that tools parse such as `:`). Rename by script with a mapping table, a dry run and checksums, never by hand.

## 3. The notebook (`docs/PROJECT.md`)

Names and section numbers are fixed across projects: `file-conventions.md`.

The living memory of the project, written by both of you. Sections that proved their worth:

- **§0 Current state (handover)**: read first in every session. What is open right now, what is waiting on whom, what
  must never be done (e.g. "never commit the local guard in X"), the next step. Rewrite it, don't append forever.
- **§1 Goals** (table: horizon → goal). **§1b Roadmap**: ordered tracks, each step with its check.
- **§2 Status board**: a table first: id · item · priority (P1–P3) · status, open items only, sorted by priority.
- **§3 Plan** per track, with hypotheses and the test for each.
- **§4 Findings**: numbered, dated, newest-relevant at the top of each section, each citing the study folder, script
  and plots that back it. Corrections are added as dated corrections, not silent edits.
- **§5 Decisions**: table `date | decision`, including who decided and why. Saves re-discussing settled questions.
- **§6 Open questions**, **§7 Backlog/ideas** (with who suggested and when; §7b postponed, §7c not doing with the reason), **§8 Discussion points for a
  collaborator** (status 💬/🗣/✅), **§9 Studies index** (folder → purpose → where its result is written down).

Keep the owner's own wording for decisions where it matters ("owner, 2026-11-16: …"). It records intent precisely.

## 4. CLAUDE.md and memory

- **CLAUDE.md** (project root): the rules that override defaults. Short, imperative, grouped: session start, what goes
  where, data safety, working style, ask-before-acting, per-repo rules, environment gotchas. Every rule should carry its
  reason somewhere (CLAUDE.md or notebook decision).
- **Memory** (one fact per file, `type: feedback | project | user | reference`): especially *feedback* — each correction
  from the owner becomes a rule with **Why** (the incident) and **How to apply**. Link related memories.
- Keep both up to date when paths or rules change (a folder move must update CLAUDE.md, memory, README, notebook).

## 5. Study folders (`workbench/<date>_<topic>/`)

- Date = when the study started; topic = short. Everything the study produces stays inside (scripts, logs, outputs,
  plots in `plots/`).
- A `README.md` per study (`assets/study_README_template.md`): question (and who asked), inputs (read only), method,
  results with numbers and plot paths, caveats, next stage.
- For a multi-step change: a **step log** in the README — one section per step with the change, the reasoning and a
  `check | result` table.
- When finished: result into the notebook (§4), an entry into the trial log (`docs/TRIALS.md`, also and especially
  for a null result), row into the studies index (§9), durable tools promoted (with OK), then the folder may be
  deleted (with OK).

## 6. Tools (`bin/`), runs and provenance

- Each script: a header comment with usage examples, `-h` printing it, `set -euo pipefail`, clear refusal messages.
- **Every run gets its own folder** `runs/<timestamp>_<mode>[_tag]/` with: outputs, log, the exact command, the
  effective configuration, and a diff/commit of the analysis code. Months later you can still say what produced a file.
- **Quick-test mode**: run on the first N chunks of one input file (cut once, cached, reused). Fixed small inputs are
  also what regression references are made on.
- **Export/derive steps** write only into our own dataset area and keep a marker file (`export.txt`) so a later
  `-f` replaces only what the tool made itself.
- Wrap the gotchas of the underlying framework inside the tool once (in O2: no `| tee` on the last device,
  `< /dev/null` on the first, process-group cleanup), instead of remembering them every time.

## 7. Restructuring an existing project

Restructuring is pure risk with no physics gain, so it is done in the strictest form of the step loop:

- One step per move (rename the umbrella; move a repo in; reorganise studies; move datasets), numbered (S1, S2, ...).
- Each step: dry-run script in `docs/<ID>_plan.sh` (prints everything; `--do` executes) → owner's yes → execute →
  checks → notebook entry. Keep the executed script as the record.
- Standard checks after each step: md5 manifest of every moved file before = after; tools still build ("no work to do");
  a smoke run bit-identical to the reference; no stale path left (`grep` for the old path, except dated history notes);
  `git status` exactly as expected in every repo.
- If a step stops halfway (unexpected file, guard fires), stop, understand, then resume with a `<ID>_resume.sh` from
  the right point with the same code.
