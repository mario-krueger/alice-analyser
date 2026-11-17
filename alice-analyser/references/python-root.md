# Python and ROOT: PyROOT, uproot and friends

Most offline work (inspecting outputs, quick numbers, fits, plots, glue scripts) happens in Python next to ROOT.
Choose the tool by the job, and know the traps that cost hours.

## Which tool for what

| job | tool | why |
|---|---|---|
| read histograms/trees into numpy, quick numbers, no ROOT install needed | **uproot** (+ numpy, awkward) | pure Python, fast, works in any venv |
| jagged/variable-length data (tracks per event) | **awkward** arrays (via uproot) | vectorised without Python loops |
| histogram objects in Python, rebinning, slicing | **hist** / boost-histogram (`h.to_hist()` from uproot) | clean API |
| quick matplotlib plots in HEP style | matplotlib + mplhep | |
| anything ROOT-specific: fits (TF1, Minuit), THnSparse, RooUnfold, RDataFrame, writing complex ROOT objects | **PyROOT** | the full ROOT, same objects as the C++ code |
| plots meant to be regenerated many times (checks, all-dataset overviews) | **SciRooPlot** (`plotting.md`) | definitions instead of canvas code |
| exact comparisons of ROOT files | `scripts/root_filecmp.C` (ROOT) | compares contents *and* errors, graphs, fits |

Install Python packages in a project venv (`python3 -m venv .venv && .venv/bin/pip install uproot awkward hist
mplhep`), not into the system or ROOT's Python. Ask before installing anything.

## uproot pitfalls

- **Errors are not in `to_numpy()`.** `h.to_numpy()` returns (values, edges) only. Use `h.values()`, `h.errors()`,
  `h.variances()`. Flow bins are excluded by default (`flow=True` includes them).
- **Coverage is not complete.** Common histograms, profiles, graphs and TTrees read fine. For less common classes
  (THnSparse/THn, TF1 with its fit result, custom classes) check support first, and fall back to PyROOT.
- **Writing is limited** to simple histograms and trees. Write complex outputs with ROOT.
- **AO2D layout:** one `DF_<id>` directory per time frame, with one TTree per table (`O2collision…`, `O2track…`, MC
  tables). Table names carry version suffixes (`_001`, `_iu`). List the keys of one DF before assuming names. Note
  that the tables are linked by index columns, so joins are your job outside the framework.
- **AO2D metadata** is a `TMap` named `metaData` (keys like `LPMProductionTag`, `RecoPassName`, `AnchorProduction`,
  `AnchorPassName`, `DataType`). PyROOT reads it directly; check whether your uproot version can.
- Remote files: uproot reads `root://` (with the xrootd extras installed), not `alien://` catalogue paths. Resolve
  those first or download.

## PyROOT pitfalls

- **Use the Python ROOT was built with.** A different `python3` cannot `import ROOT` (or crashes). Several ROOTs on
  one machine (a standalone build, the one inside alienv): source the right `thisroot.sh` / enter the right
  environment, and never mix them in one process.
- **Object ownership:** histograms read from a file disappear when the file closes. Use `h.SetDirectory(0)` or
  `ROOT.TH1.AddDirectory(False)` first. Objects created in a function may be garbage-collected by Python while ROOT
  still draws them, so keep references.
- **Batch mode** for scripts: `ROOT.gROOT.SetBatch(True)`. Avoid `TCanvas::Update` in batch (it can crash); `Print`
  the canvas instead.
- **Implicit multithreading** (`ROOT.EnableImplicitMT()`, RDataFrame) changes the processing order. Floating-point
  sums can then differ in the last bits from run to run, which breaks bit-identical regression checks. Run reference
  comparisons single-threaded.
- `TFile.Get` returns `None` for a wrong path without an error: check it. Key cycles (`name;1`) matter when objects
  were written twice.
- C++ macros from Python: `ROOT.gInterpreter.ProcessLine(...)` or ACLiC (`.L macro.C+`). ACLiC caches next to the macro
  go stale after moving folders (`pitfalls.md` §5).
- NaN ≠ NaN in comparisons; integer division and `TMath` vs numpy conventions; bin numbering starts at 1 (0 =
  underflow).

## Small habits

- Every number quoted in a report comes from a script that is kept in the study folder, not from an interactive session.
- Print results with their basis (file, object, bin range, sample size).
- Read only what you need (`uproot` with `filter_name`, `entry_stop`) on big files.
