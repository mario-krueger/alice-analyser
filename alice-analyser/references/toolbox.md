# Toolbox: what an ALICE analysis on a Mac usually needs

Start a new project by running `bash scripts/check_tools.sh` (read only). Then ask the user to install what is missing
**and needed for the task at hand**, giving the exact commands below, before trying any workaround. Installing is the
user's decision (global state), and one install beats an hour of second-choice detours.

Some tools exist but only appear after sourcing an environment (`thisroot.sh`, SciRooPlot's `env.sh`, `alienv`).
"Missing" in a fresh shell may only mean "not sourced". Ask the user where they keep them before installing a
second copy.

| tool | what for | install / where (check official docs for the current way) | notes |
|---|---|---|---|
| Xcode command line tools | compilers, git | `xcode-select --install` (or full Xcode) | the user does this; an Xcode update can require rebuilding ROOT/O2 |
| Homebrew | package manager | brew.sh | global state: every `brew install/upgrade` needs the user's yes |
| git | everything | with Xcode CLT or `brew install git` | |
| python3 (+ venv) | helper scripts, PyROOT | system or brew; project venvs | several Pythons coexist; call the intended one by path |
| uproot, awkward, hist, mplhep | reading ROOT files and quick numbers/plots in Python without ROOT | `pip install uproot awkward hist mplhep` in a project venv | see `python-root.md` for when to use PyROOT instead |
| cmake (+ ninja) | building frameworks, RooUnfold, plotting code | `brew install cmake ninja` | configure dependencies with explicit `-D<Pkg>_DIR` |
| ROOT (with PyROOT) | analysis, offline corrections, plotting | `brew install root`, or a source build (`source <root>/bin/thisroot.sh`) | a separate ROOT lives inside alienv (O2); don't mix them in one shell |
| aliBuild + alienv | building and entering O2/O2Physics | ALICE install docs (e.g. `brew install alisw/system-deps/alibuild`), then `aliBuild build O2Physics …` | builds take hours; never rebuild unasked |
| alien.py (alienpy) | grid catalogue, downloads, token | inside alienv | token: `alien-token-init` (user types the passphrase) |
| grid certificate | grid + Hyperloop | CERN CA → `~/.globus/usercert.pem`, `userkey.pem`; `.p12` into the browser/keychain | only the user can do this |
| Chrome + Claude in Chrome | reading/steering Hyperloop with the user's certificate | Chrome Web Store | site access restricted to alimonitor.cern.ch |
| pre-commit | O2Physics formatting/lint hooks | `brew install pre-commit` (or pip) | run `pre-commit run --files <file>` in O2Physics |
| O2 linter | O2Physics conventions | `python3 Scripts/o2_linter.py <file>` in O2Physics | run directly: pre-commit hides demoted warnings |
| clang-format / clang-tidy | formatting, static analysis | alisw's versions in alienv (match CI); `brew install llvm` as fallback | versions differ → findings differ; compare before/after with the same binary |
| gh (GitHub CLI) | PRs, CI status | `brew install gh`; `gh auth login` by the user | without login: prefilled compare links + public API |
| RooUnfold | unfolding | official release + the project's patch, built out-of-source | never modify the installed tree |
| SciRooPlot | plot definitions and quick check plots | `brew tap SciRooPlot/scirooplot && brew install SciRooPlot`, then source its `env.sh` | ships its own agent skill (`scirooplot`); propose it for plots (`plotting.md`) |
| poppler (`pdftotext`) | reading analysis notes, theses, papers | `brew install poppler` | ask for it as soon as a PDF must be read |
| TeX (MacTeX/TeX Live, latexmk) | analysis note, paper | `brew install --cask mactex` (large, ~5 GB) | never rebuild frozen documents (old notes, thesis) |
| coreutils (optional) | GNU `timeout`, `gsed`, … | `brew install coreutils gnu-sed` | don't make shared scripts depend on them |

## Project-level tools worth creating early

What pays off, as small bash scripts in `bin/` (each with `-h`):
`setup` (links, checks), `build` (rebuild the task and every workflow the pipeline uses), `run` (pipeline with run
folders and provenance), `fetch` (grid samples: download or stream), `token-init` (robust token creation), `export`
(task output → framework dataset, guarded), `unfold` (framework run on our dataset area, guarded), `make-config`
(validate/dump effective configs). In `tests/`: `regression.sh`, `framework_regression.sh`, an exact ROOT file
comparator (`scripts/root_filecmp.C`), a diagnostic comparator, and `tidy.sh` (clang-tidy before/after).
