# Offline corrections and unfolding frameworks

Lessons from maintaining a ROOT/RooUnfold-based framework that produced published results (multiplicity-dependent
spectra, iterative Bayesian unfolding, systematics) while extending it for new data. They apply to any offline code
whose old outputs are someone's published numbers.

## Contents
1. Backwards compatibility is requirement number one
2. Classify every change
3. The regression test on all published inputs
4. Migrating a dependency
5. Explicit beats magic
6. Inputs, outputs and manifests
7. Physics validation of the chain
8. Uncertainties deserve the same scrutiny
9. Writing it up

---

## 1. Backwards compatibility is requirement number one

After **every** change, however tiny, rerun all published inputs — including the old, fragile parts (systematics) —
and show the results are **bit-identical**. No "obviously harmless" exceptions. New features (new data formats, new
normalisations, a 1D mode) come in as **additional modes or code paths**; existing logic for the published datasets is
not altered. Value-changing fixes go **behind a switch** whose default reproduces the published state.

## 2. Classify every change

Before proposing, label it:
- **crash/robustness only** (must keep every existing output bit-identical; prove it), or
- **value-changing** (needs a switch, a physics argument, and a statement of which outputs change and by how much).

Example: a systematics step crashed on triggered variants because a lookup returned null for spectra that only exist in
one folder. Fix = skip the null (crash only, 32/32 other outputs bit-identical), **plus** flagging the physics choice
it implies (those spectra get no MC non-closure contribution) to the owner instead of deciding it silently.
Also watch for undefined behaviour that "works by luck" (casting a `THnSparse` to `TH1*` and calling `SetDirectory`).

## 3. The regression test on all published inputs

- Copy the inputs of every published dataset/variant read-only into a work area; run the full chain (unfold + syst);
  compare **exactly** with the stored outputs (all objects; histograms with errors; graphs; fits).
- Stored outputs can be older than the code (made before later changes, or without the systematics mode). Find out
  before trusting them. Regenerating them is a deliberate, owner-approved step (outputs made on copies; old files moved
  aside, not deleted; md5 of every other file unchanged), after which the references are frozen (`*.md5` in `tests/`).
- Make the comparator robust and prove it can fail (NaN == NaN handled; a one-ulp change detected).
- Report: `37/37 identical`, run time, peak disk.

## 4. Migrating a dependency

Model case: RooUnfold 2.1 (+ private patch) → official 3.1.0 + patch.
- Reproduce the published state first (old version + patch), then migrate, then prove bit-identity on all published
  inputs. Understand every difference before accepting it.
- Use the **official** release plus a small, versioned patch kept in your repo, not a private fork.
- Build out-of-source; configure with an explicit `-D<Dep>_DIR`; never modify the installed dependency trees.
- Keep the old state reproducible via git (the commit before the switch + the archived old patch), then support only the
  new version — no parallel code paths.

## 5. Explicit beats magic

Behaviour keyed on dataset names (`noDDC` → other systematics list, `triggered` → other normalisation, Pb-Pb rebinning
keyed on a specific name, a hard-coded specifier list in the plotting code) breaks silently for new datasets.
- Move toward **explicit job files**: the default needs no file; a variant states only its differences; paths relative;
  a check command (missing files, checksums) before running.
- One **dataset registry** (system, √s, labels, cross sections, aliases) instead of maps scattered over files.
- Use `.find()` (or `at()`) instead of `operator[]` on lookup maps, so a missing entry fails visibly instead of
  inserting a zero.
- Decide the naming scheme once and rename everything by script (mapping table, dry run, checksums, aliases for old names).

## 6. Inputs, outputs and manifests

Classify with the owner:
- **inputs** (irreplaceable or expensive): data and MC train outputs, dedicated generator simulations, models,
  publication files, files of unknown origin;
- **outputs** (regenerable): unfolded results, systematics, combinations.
Per dataset a manifest: checksums, origin (train/production/pass/task commit, or "unknown" stated honestly), location.
Archive inputs + the published derived outputs as regression references.

## 7. Physics validation of the chain

- **Standard candle**: one fully corrected comparison you rerun after every change of the chain (e.g. new data vs the
  same data converted from the old format vs the published result).
- Compare in stages: first **without** an optional correction on both sides, then with it. Separate effects by changing
  one thing at a time (old vs new code on the same new input, before comparing new input with old input).
- **MC closure** (unfold MC reco with its own response → truth) and **cross-generator closure** (generator A as
  pseudo-data, B as response).
- Watch items per new MC production (e.g. fraction of events with zero measured tracks, a second band in the response).
- Cuts: show that each cut removes about the same fraction in data and MC; use the same physical cut in both.
- When restricting ranges (an "analysis window"), crop all inputs in **one** place right after reading; prove that the
  extended input cropped to the old window is bit-identical to the old result.

## 8. Uncertainties deserve the same scrutiny

- Check fit status; NaN parameter errors have a cause (parameter at a limit, degenerate model, matrix not positive
  definite) — find it rather than live with it.
- Know what your unfolding errors include: a "fast mode" may propagate only the first-iteration matrix; the MC
  statistics of the response matrix are often not propagated at all. Bootstrap (Poisson-resampled replicas of data and
  MC) is the honest check.
- Systematic variations: significance (Barlow) before including them; max-of-pair vs symmetrisation decided and written down.

## 9. Writing it up

- Every implementation statement in the note checked against the code (file:line); mismatches marked as open points
  rather than smoothed over.
- Precise claims: "the regression reproduces the stored results of 9 of 10 datasets" — not "reproduces the
  published results bit by bit".
- Figures: frozen copies inside the note's repo, updated by an explicit sync script, so a rebuild alone never changes a figure.
- Read the draft as a critical referee before calling it done; then let an independent agent do the same.
