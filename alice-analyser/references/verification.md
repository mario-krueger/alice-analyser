# Verification: proving a change did what it should, and only that

The question after every step is not "does it run?" but "what exactly changed, and is that what we intended?".

## Contents
1. Baselines and references
2. Exact comparison
3. Proving the check works
4. Expected effect, and only that
5. Regression suites
6. Plots in checks
7. Independent review
8. Reporting a check

---

## 1. Baselines and references

- Before the first change: run the current code on **fixed, small inputs** (e.g. the first 3 time frames of one file)
  and keep the outputs as the baseline.
- **Rerun the baseline and compare.** If two runs of unchanged code differ, the code is not deterministic. That is a
  finding in itself (example: random repetitions re-seeded on each run; fixed with a stateless hash of the
  particle's properties, so the same particle always gets the same draw, independent of processing order).
- One baseline per configuration that matters (data, MC, each systematic variant), e.g. 18 of them.
- Stored outputs are references **only if** you know they were made with the code you compare against. Old stored files
  may document older code states; check dates and content before trusting them (it happens that most stored outputs
  predate later framework changes; regenerate them deliberately, keeping the old ones aside).

## 2. Exact comparison

- Compare **every object**, by full path, **contents and errors** (and for graphs: points and all errors; for fits:
  parameters, errors, χ², NDF, range). `scripts/root_filecmp.C` does this for ROOT files with `==`.
- Report as counts: `146 objects: 146 identical, 0 different, 0 only in A, 0 only in B`.
- **No tolerance in the pass/fail check** where the code path is deterministic. A tolerance turns "changed slightly"
  into "identical". Use a separate diagnostic tool to quantify differences (max relative deviation per histogram) when
  something does differ.
- Treat NaN == NaN as equal (otherwise NaN fit errors always "differ"), and say so in the tool.
- For moved/copied files: md5 manifests before/after. For text outputs: `diff`.
- Know your tool's blind spots (one comparator hung on files without the expected top folder; a generic one fixed it).

## 3. Proving the check works

A check that never fails proves nothing.
- **Negative test**: change one value by one ulp (`std::nextafter`) or a relative 1e-15 in a copy and confirm the
  comparator reports DIFFERENT. (An absolute 1e-15 is lost in a value above ~10: 1000 + 1e-15 == 1000 in double.)
- **Guard tests**: confirm that a refusal (protected dir, existing output) actually fires.
- If a check unexpectedly passes for something that should change, suspect the check first.

## 4. Expected effect, and only that

Before executing, write down the prediction: which outputs change, in which direction, roughly by how much; which must
stay bit-identical. Then check both halves:
- the intended change happened (e.g. an efficiency that jumps from a few % to the expected value after fixing a flag; 13/17 histograms differ
  between two seeds, and the 4 identical ones are exactly those that don't depend on the random draw);
- everything else is bit-identical (other configurations, the data path, the path without the new option).
- Internal consistency checks are cheap and strong (e.g. per multiplicity bin: Σ over pT of particle counts ==
  N × event count).
- Cross-checks with different inputs find different bugs: each new dataset type tends to expose a real
  problem (different flag semantics between Run 2 and Run 3, an auto-detection that needed full metadata, pileup).

### Diff review: nothing changed that wasn't agreed
Before reporting a code change, read your own diff hunk by hunk. Every hunk must belong to the agreed change. Look
for accidental edits (a touched neighbouring line, a renamed variable, a deleted comment, editor or formatter
changes to the whole file, line endings). Formatters (clang-format, pre-commit) may only touch the lines you changed;
if they reformat more, separate that into its own agreed step. Report the diff size ("+12/−4 in one function") so the
owner can check it too.

### Two kinds of reference
- **Regression reference** (today's output, frozen): proves that a change *did not change* anything it shouldn't.
  It says nothing about whether today's output is *correct*.
- **Correctness reference** (independent of the code under test): plain ROOT, an invariant, a hand calculation, a
  second implementation, a published number. Use this when a check should show that something is *right*.

### A check must catch the bug it covers
Run a new check against the code *before* the fix (or with the fix disabled) and see it fail. Then fix, then keep the
check. No "known failure" marks: a finding is either fixed, or explicitly accepted, with the stated guarantee
narrowed and the reason written down. Build checks generically (all data types, options, datasets), not one test per
bug, and keep the case that failed as a named case.

## 5. Regression suites

- Promote durable checks to `tests/`: a script that runs all configurations on the fixed inputs and compares exactly with
  the references, exit code 0 only if all are identical; a summary line `regression: 18/18 identical`.
- References are local (big), their checksums can be tracked (`tests/ref/*.md5`), and they are replaced only
  deliberately, with a dated note in the notebook saying why.
- For a framework with published results: run it on **all** published inputs, including the fragile old parts
  (systematics), and compare with the stored published outputs. See `offline-corrections.md`.
- For code with CI: reproduce every CI check locally before proposing a push (`o2physics.md`).
- **Choose the checks by the change's reach, each once.** Before running anything, write down which code paths,
  configurations and stages the change can reach. Reasoning can exclude what the change never executes; it cannot
  exclude what executed code computes (reordered arithmetic or a changed type can move the last bit), so every
  configuration that executes the changed code is run. Example: a change to how QA histograms are booked, where the QA
  exists only at the nominal setting → one run per code path that books it (data, MC with and without the correction),
  not the 18 systematic configurations, which never execute it; plus the specific content check (same entries per bin
  of the other axis). Logic changes (selection, filling, corrections) → the full suite. Offer a fast-lane option in the
  suite script (e.g. `regression.sh -q`).
- Inside the result path of code with published results, "obviously harmless" is no exemption: any change to code or
  configuration there gets the full rerun on all published inputs. Documentation, comments and code outside the result
  path need none; say why.

## 6. Plots in checks

Numbers say *whether*, plots say *where*. Add quick plots when a check involves distributions: before/after overlays
with ratio panels, data/MC comparisons, the location of an effect (which pT, which multiplicity). Keep them in the study
folder (`plots/<group>/`), cite the paths in the report and the notebook. Temporary and quick is fine; they are evidence,
not publication figures. A SciRooPlot program per study makes them cheap and regenerable (`plotting.md`).

## 7. Independent review

For milestones (a PR, a document draft, a framework change), spawn a fresh agent with the code/text and the question,
**not** your conclusions (otherwise it confirms them). Then verify each finding yourself in the code before acting:
in practice some reviewer findings are real bugs, others plainly wrong ("histogram X is unused" when it
is used). Record which were confirmed.

Also review your own output as a critical referee: every claim backed by a check or a source; precise words
("reproduces the stored results of 9 of 10 datasets", not "reproduces the published results").

## 8. Reporting a check

```
## Step 3: <title> (date) ✅ implemented, uncommitted
Change (+37/−16): <what, in two sentences>. Why: <one sentence or a pointer to the decision>.

| check | result |
|---|---|
| data vs baseline | ✅ bit-identical, 146/146 objects, contents + errors |
| MC noPCC vs baseline | ✅ bit-identical |
| MC new option vs baseline | ✅ 13/17 differ as predicted; the 4 identical ones don't depend on X |
| linters / pre-commit | ✅ file unchanged |
| static analysis before/after | ✅ 5 old findings, 0 new |
Side finding: <...> → notebook §4.x. Open: <...>.
```
