# Best practices: designing an analysis chain, its tests and its repositories

For users who ask for help structuring their work, or whose project has grown without a plan. Offer this as
guidance, not as a mandate: move people gradually, one visible benefit at a time (`collaboration.md` §1). Start small, and grow the structure as the analysis grows.

## Contents
0. Starting from scratch: the concept phase
1. Helping a user structure their work (coaching mode)
2. Designing the analysis chain
3. The test setup
4. Git: what goes in, what stays out, how to commit
5. Starting small
6. Code: from macros to a reusable framework

---

## 0. Starting from scratch: the concept phase

A new analysis starts with thinking, not code. Code written before the concept is settled leaves artefacts (wrong
binning, a missing variation, a normalisation that can't be fixed offline, histograms nobody needs) that the analysis
then has to live with for months, and trains have to be rerun. So first run an **interactive planning phase** with the
user. It is conceptual reasoning and questions, written down as a short concept, before the first line of code.

**Learn from what exists first.**
- Previous measurements of the same observable: papers, analysis notes, HEPData records.
- Existing O2Physics tasks for similar observables in the PWG (extend instead of reinventing), and the PWG's
  recommended datasets, selections and helper tasks.
- Ask the user, their supervisor or the conveners which of these are the references (see "whom to ask").

**Questions to settle together, one block at a time:**

| block | questions |
|---|---|
| observable | What exactly is measured (spectrum, yield, ratio, correlation, distribution)? Defined at which level (primary charged particles, which particle definition)? What final figure, and for whom (paper, note, thesis)? |
| phase space | η (or y) range, pT range, event class (INEL, INEL>0, triggered, multiplicity/centrality classes), which estimator. Why these, and what do detector and statistics allow? |
| normalisation | per event of which class? Trigger and vertex efficiency, signal loss, the event-class definition in data and MC. What is measured vs corrected? |
| corrections | efficiency × acceptance, secondary contamination (feed-down, material), particle composition, unfolding (detector response), pileup, track-to-collision association. Which are needed, and which method for each? |
| MC | Which anchored productions, which generators (nominal and alternatives), enough statistics for the response? Do the MC distributions describe data where it matters (QA comparisons)? |
| selections | event selection (trigger, vertex, pileup, TF/ROF borders), track selection; how each is validated (data/MC comparison of what each cut removes) |
| systematics | which variations (cuts, MC/generator, correction methods, normalisation), how they are combined, how significance is judged |
| datasets | which periods/passes and MC per system; statistics estimate (is the observable feasible with them?) |
| validation | closure tests, a standard candle (a known result to reproduce), cross-checks between methods or productions |
| outputs | the output specification of the task (histograms, axes, binning, variations, size), designed from the final figure backwards |

**Write the concept down** as `docs/<topic>_proposal.md` (or notebook §3), in short: the answers, the open questions,
the assumptions to test first, and a first roadmap of small steps. Agree on it with the user, and the
supervisor where relevant. Then start with the riskiest assumption (a feasibility check, a QA comparison, a toy),
not with the full chain.

**When the user wants code right away.** Give the concept round first, in the same reply. If something running
helps (motivation, checking the toolchain), add a **toy prototype** in a dated study folder (`workbench/…`), never in
the user's project: synthetic input, the planned chain end to end, its limits stated in the README ("toy, placeholder
cuts, not physics"). It is thrown away or rebuilt once the concept is agreed.

**Keep it interactive and proportionate.** Ask in blocks, bring a proposal with each question, and accept "decide
later" for what doesn't block the start. The concept is a living document, not a contract: update it, dated, when
findings change it. A two-day exploration needs a paragraph, a thesis analysis a few pages.

## 1. Helping a user structure their work (coaching mode)

- **Start from the result.** What is the final plot/table/number, for which systems, with which uncertainties, and
  for whom (paper, note, thesis)? Write the answers into the notebook's goals table.
- **Draw the chain on one page**, along the three stages (online / offline / plotting): what flows between them, where each runs (grid, laptop), what already
  exists. A plain text diagram in the notebook is enough.
- **Find the riskiest assumption** and propose testing it first (an MC that may not describe a cut, a correction
  that may not close, a dataset that may lack a table).
- **Propose a minimal structure** (§5) and a first roadmap of small steps, each with its check. Let the user choose,
  and adapt to their habits and existing code.
- **Explain the why** of each element (why a regression test, why run folders). A structure the user doesn't
  understand gets abandoned.

## 2. Designing the analysis chain

A typical ALICE analysis has **three stages** (SKILL.md, "The three stages"):
**online** (the O2Physics task on Hyperloop/grid → `AnalysisResults.root`) → **offline** (corrections, unfolding,
systematics, combinations → result files) → **plotting** (figures for checks, note and paper). Give each stage its own
repository, its own tests, and a file interface to the next stage.

- **Design from the end.** Fix what each stage needs from the previous one: an *output specification* (histograms,
  axes, binning, event classes, variations, size estimate for the largest system). Changing it later means rerunning trains.
- **Clear interfaces between stages:** files with documented content, not shared global state. Each stage can be run
  alone on stored inputs.
- **Separate analysis from plotting.** A very common problem: plotting macros that also normalise, correct, fit or
  combine, so physics hides in presentation code and every restyle risks changing a number. Instead:
  - the analysis stages compute *everything* (corrected spectra, ratios, fits, systematics with their errors) and
    write it into result files;
  - the plotting stage only *reads and presents*: no physics computations, no hidden scale factors;
  - then plots regenerate from new results with one command, restyling cannot change physics, and every number in
    a figure can be traced to a result file.
  SciRooPlot is designed for exactly this split: plot *definitions* that point to objects in result files, separate
  from *drawing* (`plotting.md`). A typical chain: task → offline framework (result files) → plotting repo
  (SciRooPlot definitions reading those files).
- **Configuration in files, not in code:** run configs (json), dataset definitions/jobs (explicit, no name magic),
  one registry for dataset properties (system, √s, cross sections, labels).
- **Variations as configuration:** systematic variants are configured copies (subwagons, `systMode`-like switches),
  run in the same pass where possible, so they stay statistically correlated and comparable.
- **Data and MC through the same code path** with the same physical cuts. MC-only parts are clearly separated
  (templated process functions, explicit switches).
- **Determinism:** no unseeded randomness. Reruns on the same input give bit-identical outputs.
- **Provenance at every stage:** each output knows its inputs, code version and configuration (run folders, manifests).
- **Inputs vs outputs:** irreplaceable inputs (train outputs of unknown origin, simulations) are protected and
  checksummed. Outputs are regenerable and may be deleted.
- **Keep the old path while building the new one.** New features are new modes; published results stay reproducible
  (`offline-corrections.md`).

## 3. The test setup

Tests in layers, from cheap and frequent to expensive and rare:

| layer | what | when | typical runtime |
|---|---|---|---|
| static checks | formatter, linters, clang-tidy before/after | every change | seconds |
| regression | all configurations on fixed small inputs, exact comparison with frozen references | every change | minutes |
| consistency | internal invariants (sums, normalisations, contamination ≥ 0) | every change | seconds |
| closure | MC through the full correction chain gives MC truth; cross-generator closure | changes to corrections | minutes–hours |
| standard candle | full chain vs a known result (published, or the same data through the old chain) | changes to the chain | hours |
| cross-production | same analysis on different passes/MC productions | new datasets | hours |
| statistics | Hyperloop wagon tests on full datasets | before trains | hours–days |

- Build the regression layer **before** the first change it should protect, with references made from the current code
  and proven reproducible.
- Fixed small inputs (the first N time frames of one file, cached) keep the regression layer fast enough to run
  every time.
- Every bug found later becomes a test case in the layer that should have caught it.
- A test that cannot fail proves nothing: negative-test the comparators.

## 4. Git: what goes in, what stays out, how to commit

**One repository per component** (task code lives in O2Physics; the offline framework, the plotting code, the note
and the project tools are each their own repo). The umbrella project tracks only its tools.

**Track:** source code, scripts, configurations, small text documentation, test scripts, `.gitignore`, and
**checksums** (`*.md5` manifests) of large references and inputs.

**Don't track binaries and generated files:**
- ROOT files (AO2Ds, `AnalysisResults.root`, unfolded results, references), PDFs, PNGs, plot outputs;
- build directories, ACLiC caches (`*_C.so`, `*_C.d`, `*.pcm`), `__pycache__`, IDE projects with absolute paths;
- downloaded samples, run folders, study (workbench) folders, local environment overrides (`env.local.sh`);
- secrets (certificates, tokens, `.env`).

Why: binaries bloat the history forever (deleting them later doesn't shrink it), don't diff, cause merge conflicts,
and often contain data that should not be public. Store large files in a proper place (EOS/CERNBox project space,
the grid) and track their **checksum and location** in git (a manifest). Git LFS only if the team agrees on it and
has the infrastructure. Frozen figures of a note (small, final, few) are the usual tolerated exception, by
deliberate decision.

Start every repo with a `.gitignore` (`assets/gitignore_template`). Check `git status` before each commit for files
that slipped through.

**Who reads the history.** People who were not there: a colleague, a reviewer, the owner in two years. They have
the repo, not your notebook, your chat or your machine. A commit is worth making when it changes tracked work in a
way such a reader needs to know; its message, and every tracked line it adds, must make sense to them.

**Useful:**
- One logical change per commit: one change a reader would want to find, review or revert on its own (not one item
  of your to-do list). Verified before it is committed; the commit is the new known-good baseline.
- A message that says what changes in the code's own words, then why and what was checked when that is not obvious:
  ```
  unfold: skip null mc non-closure lookup for triggered-only spectra      <- what, plain words

  syst crashed (exit 139) on the 5 triggered variants: the lookup of       <- why
  spectra that exist only in data/unfolded returned null.
  crash fix only: the regression on all published inputs is identical.     <- what was verified
  ```
- Names a reader can look up: files, functions, options of the repo, or terms of the field.
- The conventions of the repo you commit to (e.g. O2Physics `[PWGLF] <task>: …`) win over yours.
- Branches for changes to shared code, made from the current upstream; small PRs; CI checks reproduced locally first.
- Tags for states behind published results.
- The notebook points to the commit (finding → hash), never the other way round. To revisit an old state:
  `git worktree add ../<name> <hash>` (a separate checkout; the current work stays untouched).

**Annoying or useless (don't):**
- Private labels in anything tracked: notebook step IDs (`S4`, `W2`), section numbers (`§4.35`), names of local
  folders or studies (`b8`), chat context ("as discussed"). Nobody outside can decode them, and in a year nobody inside.
- Hashes of other repos or local states without saying what they are; dates of local events ("refreshed on …").
- Commits that only document something outside git (a refreshed local reference, moved data, a run you did). That
  belongs in the notebook or next to the local files (e.g. a `PROVENANCE.txt`).
- Diary text in tracked files: "changed in step X", "was Y until Z", "new:" in comments, "last updated" lines.
  Tracked docs describe the current state and how to use or remake things; the history is `git log`.
- Save-point commits for trivia, a commit per check, chains of "fix the previous commit" (fold unpushed fix-ups
  before sharing, with a yes) and, the other way round, a week of unrelated changes in one commit.
- Generated files, absolute local paths, personal workarounds, local test-only patches (keep those as `.patch` files,
  named in the notebook handover).

**Before proposing a commit, read the diff and the message as that stranger:** what do they gain? Does every name,
number and date mean something to them? Will every tracked line still be true after the next change? If they gain
nothing, there is no commit to propose. Agents commit only with the user's explicit yes (SKILL.md).

## 5. Starting small

Not every study needs the full structure. A reasonable growth path:
1. **Day 1:** a git repo for the code, a `.gitignore`, a notebook (`docs/PROJECT.md` with §0–§5), a `workbench/`
   folder for studies.
2. **First change to working code:** a baseline on a fixed small input and an exact comparison → the first
   regression test.
3. **Repeated commands:** turn them into `bin/` scripts with `-h`, run folders and provenance.
4. **Several datasets/variants:** explicit dataset/job definitions, a registry.
5. **Published or shared results:** frozen references, a full regression on all published inputs, tags.

Add each element when its absence first hurts, or one step before.

## 6. Code: from macros to a reusable framework

**The problem.** Typical analysis code: one or a few very large ROOT macros that read, select, correct, fit *and*
plot. Blocks are copied for each dataset or variant and edited by hand. Global state, magic numbers and hard-coded
paths are everywhere. Consequences: copies drift apart (a fix lands in one of five places), physics hides in plotting
code, nothing can be tested in isolation, and the interpreter finds errors only at run time, or never.

**The target** (scaled to the project):
- a **library** of functions/classes for the actual logic (reading inputs, corrections, unfolding steps, systematic
  variations, helpers), compiled (CMake), with clear inputs and outputs and no hidden global state;
- **thin executables** (or `bin/` scripts) per task (`unfold <dataset>`, `syst <dataset>`), configured by files and
  arguments, not by editing code;
- **plotting separate** (stage 3), reading the result files;
- in Python: the same shape, a package of functions plus small command-line scripts. PyROOT where ROOT objects are
  needed, uproot/numpy where they aren't.

**Why compile:** the compiler and static analysis catch type errors, wrong overloads, unused variables and missing
returns that the interpreter lets through. Builds are reproducible, and the code is fast and testable piece by piece.

**Migration path (each step verified bit-identical against the frozen outputs):**
1. Freeze: run the existing macro on fixed inputs and keep its outputs as the reference. Prove the rerun is identical.
2. Compile as-is with ACLiC (`.L macro.C+`). Fix what the compiler finds (each fix checked against the reference).
3. Extract repeated blocks into functions, one at a time. Parameters replace hand-edited copies.
4. Move paths, dataset lists and switches into configuration (files, a registry).
5. Split plotting out into its own stage.
6. Move the functions into a library with a CMake build, plus thin executables. Add the regression test to `tests/`.

**Guard rails:**
- *Extract when repetition is real.* The second copy is a warning, the third the signal. Don't design generic
  frameworks for hypothetical needs ("simplicity first").
- *Keep the owner's style and comments* (naming, structure, their histogram descriptions). It is their code, made
  cleaner, not replaced.
- *Old results stay reproducible:* if the old macro produced published numbers, the refactored code must reproduce
  them bit by bit, or the differences must be understood and switched (`offline-corrections.md`).
- *Respect the workflow:* if the user prefers their macros, help them inside that workflow (e.g. compile with ACLiC,
  extract the worst duplications) rather than forcing a rewrite. Proportionality: a one-off exploration stays a
  script in the workbench.

