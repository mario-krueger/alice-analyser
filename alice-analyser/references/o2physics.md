# O2Physics / ALICE analysis tasks: how we test and structure the work

Not physics advice — lessons about workflow, testing and tooling around an O2Physics analysis task, learned while
bringing a Run 2-era task to a reviewed, CI-clean PR and validating it on many datasets.

## Contents
1. Where code lives
1b. Locate the local ALICE setup first
2. A local run harness
3. Testing a task change
4. CI parity before any PR
5. Code patterns that helped
6. MC and data-format pitfalls to check (not assume)
7. Grid and Hyperloop
8. Designing the output

---

## 1. Where code lives

- The analysis code lives **only** in the O2Physics checkout (built with aliBuild). The project umbrella links to it
  (`o2physics/checkout`, `o2physics/build`, `o2physics/ours/` = the task files) and holds configs, scripts, tests, notes.
- Work on a topic branch made from `upstream/master`. Don't pull/update a checkout that has local changes without asking.
- Before reporting a finding in someone else's O2Physics code: compare with `upstream/master` (the checkout may be behind).
- Other people's tasks/producers you depend on (e.g. a colleague's table producer): don't change them; collect problems
  as discussion points with file:line against upstream. Local test-only patches stay uncommitted and are named in the
  handover.

## 1b. Locate the local ALICE setup first

Every session needs the same facts before touching O2. Find them once (read only), confirm them with the user, and
store them in one `env.sh` (overrides in an untracked `env.local.sh`), so no script hard-codes a path.

| fact | typical default (aliBuild) | how to check |
|---|---|---|
| aliBuild work dir | `ALIBUILD_WORK_DIR=~/alice/sw` | `echo $ALIBUILD_WORK_DIR`; `ls ~/alice/sw` |
| O2Physics git checkout (where code is edited) | `~/alice/O2Physics` | `git -C <dir> remote -v; git -C <dir> status -sb` (local changes? which branch? fork + `upstream` remote?) |
| O2Physics build dir (incremental ninja builds) | `$ALIBUILD_WORK_DIR/BUILD/O2Physics-latest/O2Physics` | contains `CMakeCache.txt`; the ninja binary is in its `CMAKE_MAKE_PROGRAM` entry |
| alienv package to load | `O2Physics/latest` (or a dated tag) | `alienv q \| grep -i O2Physics` |
| grid certificate | `~/.globus/usercert.pem`, `userkey.pem` | `ls ~/.globus` |
| grid token | — | inside alienv: `alien-token-info` (see `grid-hyperloop.md` §3) |

Patterns that worked:
- **Load alienv inside scripts** with `eval "$(alienv printenv O2Physics/latest)"`, skipped when `O2PHYSICS_ROOT` is
  already set. One-off commands: `alienv setenv O2Physics/latest -c <cmd>`.
- **Incremental builds**: `ninja -C <build dir> <target>`, where the targets are the workflow names
  (`o2-analysis-lf-…`). Put `<build dir>/stage/bin` first on `PATH` so freshly built binaries win over installed ones.
  Rebuild every workflow your pipeline uses, not only your task, so that table definitions match.
- **macOS** (needed in some setups; check whether yours does): ROOT's JIT inside O2 wanted the SDK headers
  (`SDKROOT=$(xcrun --show-sdk-path)`, `CPATH=$SDKROOT/usr/include/c++/v1`).
- Convenience links in the project (`o2physics/checkout`, `o2physics/build`, `o2physics/ours/<file>`) make the
  checkout browsable from the project, but tools read the paths from `env.sh`.
- The O2 environment and a separately installed ROOT (for offline frameworks) are different worlds: use separate
  shells/scripts, and never source both.
- Grid files: a `fetch` tool that checks the token first, lists `AO2D.root` below an AliEn folder, and downloads or
  streams a sample (`grid-hyperloop.md` §4–5).

## 2. A local run harness

Wrap `o2-analysis-*` pipelines in one script (`bin/run data|mc [-i input] [-n NDF] [-s key=val] [-t tag]`):
- configuration = a JSON (`config/<mode>.json`) + a task list (`config/<mode>.tasks`); `-s` overrides single keys;
  validate configs with a tool that dumps the effective config of each device;
- every run → `runs/<timestamp>_<mode>_<tag>/` with `AnalysisResults.root`, log, exact command, effective config,
  `git diff` of the task: provenance for free;
- `-n N`: cut the first N dataframes of the first file once into a cached slice — the fixed input for quick tests and
  regression references;
- auto-detect needed converters from the tables in the input file (old table versions, Run 2 converters) instead of
  hand-maintaining them;
- DPL gotchas handled once inside the script: no `| tee` on the last device, `< /dev/null` on the first, kill the
  process group on exit;
- `bin/build` rebuilds not only your task but every workflow the pipeline uses (services, QA, converters) from the
  same source state, so service versions never silently differ;
- separate pipeline variants where the services differ (Run 3 vs converted Run 2: `-run2` event selection /
  propagation services, track selection `isRun3: false`).

## 3. Testing a task change

- Baseline first: data, MC, MC without the optional correction, and every systematic variant on the fixed slices
  (e.g. 18 configurations), each rerun to prove determinism.
- After each change: the whole suite, exact comparison of every histogram incl. errors (`scripts/root_filecmp.C`).
  Expected differences predicted beforehand and explained one by one; everything else bit-identical.
- Add consistency checks inside or next to the task (e.g. Σ_pT particles == N × events per multiplicity bin).
- Test with **real, different inputs**, not just one: several collision systems, years, reconstruction passes,
  low field, converted Run 2 and Run 1. Each new input type tends to find a real problem. Deviations can
  come from the reconstruction or the MC production, not only from your code: compare across productions before
  concluding.
- Keep a step log (`workbench/<date>_<task>/README.md`) with one section per change and a check table.

## 4. CI parity before any PR

Propose a push or PR only when it is clean. Reproduce every CI check locally and show the output:
- `pre-commit run --files <file>` (clang-format, cpplint, O2 linter hook, include format): file must stay unchanged;
- `python3 Scripts/o2_linter.py <file>` **directly**: pre-commit's "Passed" hides *demoted* checks (magic numbers,
  const-ref in range loops, constexpr naming) which still annotate the PR → require 0 issues and 0 tolerated warnings
  introduced by you;
- clang-tidy with the repo's `.clang-tidy`, merge-base vs working tree, only new findings matter (a local stand-in for
  the CI code checker; alisw's clang-tidy may need the Apple-clang PCH flags removed from the compile command);
- O2Physics naming: constexpr variables CamelCase **without** `k` (only enum constants have `k`);
- comment diff old vs new (the author's comments carried over verbatim);
- regression suite bit-identical (or differences as intended).
- Keep a PR description file (`docs/pr/<name>/PR_DESCRIPTION.md` + `PR_GITHUB.md`) updated with every change (grouped: corrections that change outputs, new options,
  robustness, output changes); claims must match what was tested. CI workflows to mirror: `.github/workflows/`.

## 5. Code patterns that helped

- **One templated implementation, thin process wrappers**: `processMC` / `processMCnoPCC` call `processMCImpl<...>`;
  optional columns via `if constexpr (requires { particle.pccWeight(); })`. No code duplication, and the variant without
  the optional table needs no dummy producer.
- **Guard against two process switches enabled at once** (silent double filling otherwise).
- **Deterministic pseudo-randomness**: derive per-particle draws from a hash (e.g. splitmix64 over momentum, vertex,
  PDG code + a configurable seed offset) instead of a seeded generator. Same particle → same draw in every fill,
  independent of order, cuts and subtrains; up/down variations correlated; runs bit-reproducible.
- Avoid quadratic loops over tracks/collisions (fine in pp, fatal in Pb-Pb); check run time on the largest system.
- Comments brief, lowercase, no references to private studies; explanations go to the notes.

## 6. MC and data-format pitfalls to check (not assume)

Measure on a real file before relying on a flag's meaning:
- the same flag can mean different things in converted Run 2 and native Run 3 MC (e.g. `fromBackgroundEvent`:
  embedded pileup in Run 2; set for the main event, source 0, in Run 3 — a filter on it removed all primaries);
- auto-detection (`isMC: auto`) may need fully defined metadata; set it explicitly in test configs;
- one MC collision can be reconstructed several times; tracks can belong to particles of other MC collisions; decide
  the treatment with numbers first (how often, what are the extra ones);
- trigger/selection paths differ by period (Run 1 INT1 vs kINT7 vs TVX); a wrong path selects ~0 events silently;
- event selection bits: compare the rejection vs multiplicity in data and MC before choosing defaults per system.

## 7. Grid and Hyperloop

- Token creation may fail silently with some OpenSSL versions: wrap it in a tool that checks the result.
- Streaming (`alien://` lists) is convenient for small data files; the catalogue picks replicas by closeness, not speed
  → download single large MC files instead.
- State sizes before fetching; keep local samples small; larger statistics via Hyperloop wagon tests.
- Hyperloop with the owner's certificate: read freely, every state-changing click needs an explicit yes. **An activated
  wagon with a successful test is automatically composed into a full train** → keep test wagons deactivated.

## 8. Designing the output

"Design from the end": decide what the offline step needs before the trains run.
- Write an output specification: folders per event class, axes per collision system, which histograms are sparse,
  a size estimate for the largest system and all systematic variants.
- Put the data/MC comparisons into the task output (cumulative event cut flow, each selection bit vs multiplicity,
  N−1 and cumulative track-cut matrices, uncut DCA for resolution fits). It "rules out all the nonsense cuts" and makes
  cut choices arguable with plots.
- Bin QA histograms so they can be rebinned cleanly (a bin centred at zero, segments that rebin by standard factors).
- Same physical cut in data and MC.
