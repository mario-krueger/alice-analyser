# Pitfalls that keep coming back

Technical traps that come up again and again (macOS, zsh, ROOT, O2, grid). Each entry: symptom → cause → fix.
Check this list before writing shell commands or scripts on a new machine. It saves the owner from asking "why don't
you do it right the first time?".

## Contents
1. zsh is not bash
2. BSD (macOS) tools are not GNU tools
3. Scripts: `set -e`, pipes, exit codes
4. macOS file system
5. ROOT and ACLiC
6. C++ in analysis code
7. O2 / DPL / grid
8. CI, linters, GitHub
9. Environments and versions
9b. Environment variables
10. Agent-session specifics
11. Scripting craft: patterns that worked
12. On Linux (lxplus, servers)

---

## 1. zsh is not bash

The agent's shell is often the user's login shell, which on macOS is **zsh**, even when the tool is called "Bash".

| symptom | cause | fix |
|---|---|---|
| `for a in "x -i y"; do cmd $a; done` passes one argument → `$3: unbound variable` | zsh does not word-split unquoted `$var` | use arrays: `args=(-i x -n 3); cmd "${args[@]}"`, or a bash script |
| `echo =====` → `(eval):1: ===== not found` | a word starting with `=` is expanded to a command path | quote it: `echo '====='` |
| `ls include/*.h`, `grep --include=*.cxx` → `no matches found` and the command aborts | zsh errors on unmatched globs | quote the glob: `--include='*.cxx'` |
| `$FILE:e`, `$DIR:h` behave strangely | zsh history modifiers on `:` | brace it: `${FILE}:e` |
| `read -a`, `declare -A`, `${!arr[@]}` differ or fail | bash-only syntax | write a bash script |

**Rule:** anything with loops over arguments, arrays, `read` or word splitting goes into a file starting with
`#!/usr/bin/env bash` (or `bash -c '…'`). Scripts meant for others must be bash scripts anyway.

## 2. BSD (macOS) tools are not GNU tools

| GNU (Linux) | macOS | note |
|---|---|---|
| `sed -i 's/a/b/' f` | `sed -i '' 's/a/b/' f` | without `''`, BSD sed takes the script as the backup suffix |
| `sed -r` | `sed -E` | `-E` works on both |
| `md5sum f` | `md5 -r f` | recent macOS also ships `md5sum`; older ones don't |
| `readlink -f p` / `realpath p` | `realpath` on recent macOS; portable: `python3 -I -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' p` | |
| `find -printf` | not available | `find … -print0 \| xargs -0 stat -f …` |
| `stat -c %s` | `stat -f %z` | |
| `date -d '…'` | `date -j -f …` | |
| `cp --parents`, `xargs -r` | not available | write it out |

Availability differs between macOS versions and with Homebrew installed (`timeout`, `gsed`, newer `grep` features
come from Homebrew or recent releases). Check with `which <tool>` / a one-line test on the machine instead of assuming,
and don't make scripts for other people depend on Homebrew-only tools.

Write portable forms where it costs nothing (`sed -E`, `find -print0 | xargs -0`). Otherwise detect the OS.

## 3. Scripts: `set -e`, pipes, exit codes

- `set -euo pipefail` at the top. But a step that *intentionally* exits non-zero (a regression test exits 1 on
  "different") stops a `set -e` plan in the middle. Capture it: `rc=0; cmd || rc=$?`.
- `cmd | tee log` hides `cmd`'s exit code without `pipefail`; with DPL, `tee` on the last device also breaks the run
  (see §7).
- `grep -c` exits 1 when the count is 0 → `n=$(grep -c x f || true)`.
- `cmd | grep -q x` under `pipefail` can report failure *although grep matched*: `grep -q` exits at the first match,
  `cmd` gets SIGPIPE, and pipefail counts that. Write the output to a file or variable first, then grep it.
- ROOT with `-q -e '<expr>'` exits with the value of the last expression (e.g. bytes written), not 0. Don't
  treat that as success or failure: check the actual result.
- Variables in `rm -rf "$DIR/"*`: an empty `DIR` removes `/*`. Use `set -u` plus an explicit `[[ -n "$DIR" ]]` guard.
- Heredocs: `<<'EOF'` (quoted) for literal content, `<<EOF` expands `$vars` and backticks.
- Bulk renames with `sed` over many files: dry run first (count matching lines per file), apply on `--do`.

## 4. macOS file system

- **Case-insensitive** (APFS default): `o2physics` and `O2Physics` are the same path. A new name can collide with an
  existing one in a different case. Check first.
- **`.DS_Store`** appears in any folder Finder has shown → `rmdir` fails with "Directory not empty", and md5
  manifests differ. Exclude it (`! -name .DS_Store`).
- `mv` on the same volume keeps the modification and creation dates; `cp` resets them. Use `mv` for renames.
- Paths with spaces (`Application Support`, iCloud `Mobile Documents`): always quote.
- Absolute paths are baked into build caches (CMake `CMakeCache.txt`, Xcode projects, ACLiC `.so`/`.d`/`.pcm`). After
  moving a folder, rebuild them; don't trust "it still runs".

## 5. ROOT and ACLiC

- `root -q 'macro.C+(args)'`: the function called must have the **same name as the file**.
- Stale ACLiC caches (`*_C.so`, `*_C.d`, `*_ACLiC_dict_rdict.pcm`) from an old path fail to load *silently*: a script
  that greps the output then prints nothing. Delete the three files (regenerable caches); they are rebuilt on the next use.
- Several ROOT installations: `unset ROOTSYS LD_LIBRARY_PATH DYLD_LIBRARY_PATH` and source the intended `thisroot.sh`
  explicitly. Inside alienv (O2) the ROOT is a different one: don't mix the two in one shell.
- Histograms belong to the file they were read from: after `TFile::Close` they are gone, unless
  `TH1::AddDirectory(false)` or `SetDirectory(nullptr)`.
- `NaN != NaN`: exact comparisons must treat NaN pairs as equal, or every NaN fit error "differs".
- PyROOT in batch: `TCanvas::Update` can crash; `Print` the canvas instead.
- `TKey` cycles (`name;1`, `name;2`): compare by full path including the cycle, or know which cycle is read.
- A comparator that assumes a folder layout may hang or skip on files without it: use a layout-agnostic one
  (`scripts/root_filecmp.C`).
- Reading PDFs (analysis notes, papers) from the shell needs `poppler` (`pdftotext`), often not installed. If your own tools can't read the PDF, ask the user to install it (`brew install poppler`)
  instead of trying workarounds.

## 6. C++ in analysis code

- `std::map::operator[]` inserts a default value for a missing key (a missing cross section silently becomes 0).
  Use `.at()` or `.find()`.
- `static_cast<TH1*>` on something that is not a TH1 (e.g. `THnSparse`) is undefined behaviour that may "work".
  Use `dynamic_cast` and handle `THnBase` separately.
- Unseeded or reseeded random generators make runs irreproducible. Use stateless hashes of the object's properties
  when the draw must be stable.
- `uint32` weights from a double that can be `+inf`: undefined behaviour. Clamp first.
- Quadratic loops over tracks are invisible in pp and fatal in Pb-Pb.

## 7. O2 / DPL / grid

- DPL pipelines: no `| tee` on the last device; `< /dev/null` on the first (otherwise it may wait on stdin); clean up
  the whole process group on exit (orphans keep shared memory and ports).
- `isMC: auto` style auto-detection needs complete metadata in the input; set it explicitly in tests.
- Converted Run 2 / Run 1 inputs need different service tasks (`-run2` variants) and data-model converters. Detect
  converters from the tables in the file.
- `alien-token-init` can fail **silently** with some OpenSSL versions: wrap it and check that a valid token exists.
- `alien://` streaming picks replicas by closeness, not speed (a file at 40 kB/s while downloading reaches 15 MB/s).
  Stream small files, download big ones.
- Never type the grid passphrase for the user: open the terminal command and let them type.
- Hyperloop: an activated wagon with a green test joins the next automatic train over the full dataset.

## 8. CI, linters, GitHub

- `pre-commit` "Passed" while the O2 linter still annotates the PR: demoted checks are only shown when
  `Scripts/o2_linter.py <file>` is run directly.
- O2Physics `.clang-tidy`: constexpr variables CamelCase **without** `k`; only enum constants take `k`.
- alisw clang-tidy cannot read the Apple-clang precompiled header: drop the PCH flags from the compile command.
- `gh` not logged in: open a PR via a prefilled `compare/<branch>?quick_pull=1&title=…&body=…` link. CI status is
  readable without login through the public GitHub API.
- A local checkout can be behind upstream: compare with `upstream/master` before reporting a bug in shared code.

## 9. Environments and versions

- A needed tool is missing: first use what you have (an agent's own file reader may read PDFs); if a tool is genuinely
  needed, ask the user to install it (exact command) before improvising a second-choice route.

- Several Pythons: the system/Xcode `python3` is not the one with ROOT bindings or project packages. Call the
  intended interpreter by path or variable (e.g. `$SCIROOPLOT_PYTHON_EXECUTABLE`).
- Old installs lying around: a stale `install/` folder of a library may hold an older version than `build/`. Source
  the one you mean, and check the version (`srp info`, `root-config --version`).
- Dependencies built against a specific library version: configure with explicit `-D<Pkg>_DIR`. Don't let CMake pick
  up whatever it finds first.

## 9b. Environment variables

Environment variables decide which ROOT, which Python, which libraries and **which folders** a tool uses, and they
leak silently from one context into the next.
- **Path variables decide where tools write.** A framework that writes its outputs next to its inputs, run with
  `DATASETS_BASE_DIR` pointing at protected data, overwrites that data. Set such variables inside the script from
  `env.sh`, check them with a guard (resolved real path, refuse protected dirs), and never export them globally.
- **Stale or inherited values point somewhere by accident.** A variable set earlier in the session, by the user's
  shell profile, or by a previously sourced environment can silently redirect a tool to another dataset, build or
  installation. Before any step that writes or deletes, print the effective paths the tool will use and check them
  against the plan (part of the dry run).
- **Don't pollute the user's environment.** Set variables *inside* scripts, or as a prefix of one command
  (`VAR=x cmd`), so they die with the process. Don't `export` into a shell that persists, the user's terminal or a
  long-lived agent shell. Don't append to `PATH` repeatedly. Never source project settings from the user's startup files.
- **Two ROOTs, two worlds.** `ROOTSYS`, `PATH`, `LD_LIBRARY_PATH`, `DYLD_LIBRARY_PATH`, `PYTHONPATH` and
  `ROOT_INCLUDE_PATH` from one installation break the other. Scripts for the standalone ROOT start by unsetting them
  and sourcing the intended `thisroot.sh`. O2 work happens inside alienv only.
- **Don't load an environment twice:** load alienv in a script only when it isn't active yet (e.g. `O2PHYSICS_ROOT`
  unset). Nested loads stack paths and versions.
- **macOS strips `DYLD_*`** when launching system-protected binaries (SIP), e.g. through `/usr/bin/env` or `/bin/bash`.
  Library paths set before a `#!/usr/bin/env bash` script may silently vanish inside it. Set them inside the script.
- **Interpreter variables** (`SCIROOPLOT_PYTHON_EXECUTABLE`, a venv's `python`): call the intended interpreter
  explicitly rather than relying on `PATH` order.
- **Use `set -u`** so an unset variable is an error, not an empty string (`rm -rf "$DIR/"*`!). Use `${VAR:-default}`
  only for a deliberate default.
- **Record what matters:** the run folder's provenance includes the relevant variables (which ROOT, which O2 package,
  which dataset dir). Never record secrets: token or proxy paths are fine, their contents are not.
- **Never change the user's global environment** (shell startup files, `launchctl setenv`) without a yes. Keep
  project settings in `env.sh`, with local overrides in an untracked `env.local.sh`.

## 10. Agent-session specifics

- The working directory of the shell tool may reset between calls: use absolute paths, or `cd` inside the same command.
- Output of long commands gets truncated: write logs to a file and summarise them (`grep`, `tail`).
- Long runs (test suites, builds, multi-file jobs) in the background, with an expected duration. Don't poll in a tight loop.
- Files changed by the user or another tool between your reads: re-read before editing. Don't overwrite their changes.

## 11. Scripting craft: patterns that worked

The project's `bin/` tools and plan scripts converged on a few habits. They make scripts safe to run, easy to read
for the owner, and easy to trust months later.

**Shape of a tool**
```bash
#!/usr/bin/env bash
# <one line: what it does>.
#
#   bin/tool NAME                 # the common case
#   bin/tool NAME -f              # with an option, and what it means
#
# Safety: <what it never touches, what it refuses>.
set -euo pipefail
source "$(dirname "$0")/../env.sh"          # one place for paths

NAME="" FORCE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -f) FORCE=1; shift ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;  # the header comment *is* the help text
    -*) echo "unknown option $1" >&2; exit 1 ;;
    *) NAME="$1"; shift ;;
  esac
done
[[ -n "$NAME" ]] || { sed -n '2,9p' "$0"; exit 1; }
```
- The usage examples live in the header and `-h` prints them: documentation that cannot drift from the script.
- Validate inputs early (names by regex, files exist) with messages that say what to do.
- **Guards before side effects**: resolve real paths, refuse protected targets and existing outputs, *then* `mkdir`.
- Arrays for argument lists (`OVERRIDES+=("$2")`, `"${OVERRIDES[@]}"`); quote every expansion.
- Small python helpers run with `python3 -I` (isolated: no surprises from the current folder).

**Make every run traceable**
- Output into a new folder per run (`runs/<timestamp>_<mode>_<tag>/`) holding the exact command line, the effective
  configuration, the log, and the code state (`git rev-parse HEAD` + `git diff`).
- A marker file (`export.txt`) in every output folder a tool creates; `-f` replaces only folders that carry the marker.
- A one-line summary at the end that a human or a script can check (`regression: 18/18 identical`), plus an exit code
  that means the same thing.

**Plans for risky operations**
- Dry run by default, `--do` to execute, a `run()` wrapper that echoes each command and executes only with `--do`.
- Preconditions at the top (`target exists → stop`).
- An md5 manifest before, a comparison after (sorted, `find -print0 | sort -z | xargs -0 md5 -r`), excluding `.DS_Store`.
- Numbered sections (`== 1. move`, `== 2. check`), so a stopped run can be resumed from a known point with a
  `*_resume.sh`.
- Keep the executed plan script as the record of what was done; don't edit it afterwards.

**Deterministic and checkable**
- Sort anything listed (`sort`, `sort -z`) so outputs and manifests are comparable between runs.
- Fixed small inputs (first N chunks, cached) for quick tests and references.
- Compare outputs with a tool that reports counts (identical / different / only in A / only in B).
- Separate "is it identical?" (exact, pass/fail) from "how different is it?" (a diagnostic tool).

**Keep scripts where they belong**
- Throwaway scripts in the study folder (or the session scratch dir), next to their outputs; durable ones are promoted
  to `bin/` or `tests/` deliberately.
- One script per purpose; a study's `run.sh` calls the tools rather than copying their logic.
- Temporary files in a scratch directory, never in the repo or next to protected data.

## 12. On Linux (lxplus, servers)

Most of this file assumes macOS. On Linux:
- GNU tools: `sed -i 's/a/b/' f` (no `''`), `md5sum`, `readlink -f`, `stat -c`, `date -d`, `timeout`.
- Trash: `gio trash <path>` (desktop systems) or a dated holding folder. Servers often have no Trash at all.
- Case-sensitive file systems: `O2Physics` and `o2physics` are different, so watch for scripts that rely on macOS
  case folding.
- Shared machines (lxplus): home quotas are small and AFS/EOS have their own semantics. Big outputs go to EOS or a
  work area. Never run heavy jobs on login nodes (use batch/HTCondor, with the user's yes).
- `scripts/check_tools.sh` assumes macOS in parts (Xcode, Homebrew). Read its output with that in mind.

