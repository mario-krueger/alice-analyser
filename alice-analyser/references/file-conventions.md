# File conventions: the same names in every project

A user who has worked with this skill once should find their way in the next project immediately. So the agent's
working files always have the **same names, places and meanings**. Problem-specific files are added *inside* this
system, never as alternatives to it.

**No synonyms.** There is one notebook (`docs/PROJECT.md`). Not `plan.md`, `braindump.md`, `notes.md`, `TODO.md`,
`STATUS.md` or `session_3.md`. Brain dumps, plans, todos and status all go into their fixed section of the notebook.
If a project already has its own conventions, agree with the user on a mapping once, write it into CLAUDE.md, and
keep it.

## The fixed files

| path | what it is | written by | in git? |
|---|---|---|---|
| `CLAUDE.md` | rules for the agent in this project: zones, safety, working style, per-repo rules | agent + user, agreed | no (private) unless the user wants it |
| `README.md` | how to use the project's tools | agent, reviewed | yes |
| `env.sh` (+ `env.local.sh`) | all machine-specific paths and settings (local overrides untracked) | agent | `env.sh` yes |
| `docs/PROJECT.md` | **the notebook**: state, goals, plan, findings, decisions, questions (sections below) | both | no (private) |
| `docs/<topic>.md` | a topic note too long for the notebook (see name patterns) | agent | no |
| `docs/<ID>_plan.sh`, `docs/<ID>_resume.sh` | dry-run plan scripts of risky steps, kept as executed | agent | no |
| `docs/pr/<name>/PR_DESCRIPTION.md`, `PR_GITHUB.md` | long and copy-ready PR texts, updated with every change | agent | no |
| `workbench/<YYYY-MM-DD>_<topic>/README.md` | one study: question, inputs, method, results, caveats, step log | agent | no (git-ignored) |
| `runs/<YYYYMMDD-HHMMSS>_<mode>[_<tag>]/` | one run with provenance (files below) | tools | no |
| `tests/README.md`, `tests/*.sh`, `tests/ref/` | regression suite, comparators; references local | agent, with OK | scripts yes, refs no |
| `.gitignore` (per repo) | keeps binaries, outputs, playground and secrets out of git (`assets/gitignore_template`) | agent | yes |
| `share/` | the user's material for the agent | user | no; agent read only |
| memory files | durable rules and facts across sessions (one fact per file, `type: feedback/project/user/reference`) | agent | n/a |

### `docs/PROJECT.md`: fixed section numbers

Same numbers in every project, so "§4.12" or "§5" means the same kind of thing everywhere:

| § | section | what goes there |
|---|---|---|
| §0 | Current state (handover) | read first; in flight, waiting on, must-not-do, next step. Rewritten, not appended forever |
| §1 | Goals | horizon → goal |
| §1b | Roadmap | ordered tracks and steps, each with its check |
| §2 | Status board | a table first, no intro: `id \| item \| priority \| status`, sorted by priority (P1 = blocks the goal, P2 = needed, P3 = nice). Only open items; IDs stay fixed until the owner asks for a renumbering |
| §3 | Plan | per track: hypotheses with their tests, step details |
| §4 | Findings | `§4.N <title> (<date>; <study folder>, <plots>)`: numbered, dated, with evidence. §4.x Risks / watch items |
| §5 | Decisions | `date \| decision (who, why)` |
| §6 | Open questions | numbered; answered ones marked with the date and the answer |
| §7 | Ideas / backlog | `**<idea>** (<who>, <date>): …`; minor findings land here so nothing is lost. **§7b Postponed** (with the condition to resume) and **§7c Not doing** (decided against, with the reason and date; checked before proposing anything) |
| §8 | Discussion points for <colleague> | `# \| point \| where \| status 💬/🗣/✅` |
| §9 | Studies index | `folder \| purpose \| result in \| durable tools \| size` |

Status markers everywhere: ✅ done · 🔧 in progress · ⏳ next · 💬 needs discussion · ❌ dropped · 👁 watch.

### Name patterns

- **Dates:** `YYYY-MM-DD` in text and study folders; `YYYYMMDD-HHMMSS` in run folders; `_<YYYYMMDD>` suffix for
  Trash and holding folders (`~/.Trash/<name>_<YYYYMMDD>`, `<data>_outdated_<YYYYMMDD>`).
- **Step IDs:** a letter for the track plus a number (`B1` task fix, `S2` restructuring, `W2` workflow/tests, `U1`
  framework, `T1` tooling…), with a letter suffix for sub-steps (`W2b`). The same ID is used in the roadmap, the status
  board, plan scripts (`docs/W2b_plan.sh`), the study step log ("Step B13") and the commit message.
- **Topic notes:** `docs/<topic>.md` for notes, `docs/<topic>_review.md` for reviews (`review_fresh.md` = an
  independent-agent review), `docs/<topic>_inventory.md` for read-only surveys, `docs/for_<person>.md` for points
  collected for a colleague, `docs/<topic>_proposal.md` for a design to approve.
- **Inside a study folder:** `README.md`; per step `<id>.sh` (runs), `<id>_eval.C|.py` (evaluation), `<id>/` (outputs);
  `DefinePlots.py` → `plots/<group>/`; `run.sh` for the whole study; check outputs (`before.md5`, `after.md5`,
  logs) in a subfolder named after the step.
- **Run folders** (as an O2 run harness can write them) **contain:** `AnalysisResults.root` (outputs), `command.sh` (exact command), `config.json` /
  `dpl-config.json` (effective configuration), `workflow.tasks`, `input.txt`, `code.diff` + `provenance.txt` (code
  state), `log.txt`.
- **Dataset names:** one scheme for the whole project (e.g. `<system>_<√s in GeV>[:<variant>]`), no `.` in names,
  characters that tools parse (`:`, `@`) reserved.

## Keeping the living documents lean

From time to time (at the end of a larger step, or when a document gets long), review the living documents and
*propose* a clean-up to the owner:
- remove what is done or irrelevant from §0, §2, §6 and §7 (results stay in §4, decisions in §5);
- compress §0 to the current state (history belongs in §4/§5, not in the handover);
- move obsolete study rows in §9 out once their results are recorded;
- renumber status-board IDs when they have grown large (with the owner's OK). Don't renumber findings (§4.N) or
  decisions that other documents, code comments or commit messages cite: keep those numbers, or record a mapping.

Show the proposed changes as a diff or a list, apply them only after a yes, and never delete a result or a decision:
those move, they don't vanish.

## When something new is needed

1. Does it fit an existing place? (A thought → a notebook section. A check → a study. A reusable script → `bin/` or
   `tests/`, with OK.)
2. If not: pick a name following the patterns above, and add one line about it to CLAUDE.md or the notebook (§9 for
   studies), so the next session knows it exists and what it means.
3. Never create a second file with the same purpose under another name.
