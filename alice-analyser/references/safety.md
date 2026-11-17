# Safety: not destroying things on the owner's machine

The owner's computer holds things that cannot be recreated: datasets whose producing jobs are unknown, archived analysis
code behind publications, a thesis, other people's uncommitted work. An agent that is fast but occasionally destructive
is worse than useless. Default to: read freely, write only where you are sure, reversibly.

## Protected places

- At the start, ask which places are read-only and record them in CLAUDE.md with the reason. Typical answers:
  - production/published datasets ("irreplaceable: unknown which trains produced them");
  - archived code and frozen documents (a LaTeX rebuild writes aux files and re-links living plots, changing the record);
  - material the owner hands you (`share/`);
  - other people's repos and uncommitted work (a colleague's producer; the owner's local changes in a sub-repo).
- **Read-only means no indirect writes either**: no builds, no compiling PDFs, no scripts that write next to their
  inputs, no tools whose output directory defaults to the input directory pointed at that place.
- To work with something from there: copy it into a study folder, `chmod a-w` the copy, work on the copy.

## Guards in code

Rules in memory get forgotten; guards in tools don't.
- Resolve real paths (symlinks!) and refuse targets inside protected dirs, **before** creating anything.
- Refuse to overwrite existing outputs unless `-f`; and with `-f`, refuse unless a marker file shows the tool made it.
- Test the guard (it must refuse, immediately) after every change to the tool.

## Moves, deletions, cleanups

- `mv` to the Trash or to a dated holding folder (`<data>_outdated_<YYYYMMDD>` next to the data), never `rm -rf`. The owner empties
  it when happy. State sizes.
- Use `mv` for renames on the same disk: it keeps modification/creation dates; copying resets them.
- Any bulk operation: dry-run script first (prints every action), then `--do` on approval. Precondition checks at the top
  (`target exists → stop`). md5 manifest before, compare after.
- If a run stops halfway (Finder's `.DS_Store` made `rmdir` fail), don't patch it live: understand, then resume from the
  right step with a resume script.
- Disk budget: state the size before any download or copy, and the remaining budget. Prefer streaming or small samples.


### Trash mechanics (macOS)
- `mv <path> ~/.Trash/<name>_<date>`: give it a dated, unique name. With an existing item of the same name in the Trash,
  `mv` would overwrite it (a file) or move into it (a folder).
- Items moved with `mv` have no Finder "Put Back" information. Record the original path in the report or notebook,
  so restoring is a plain `mv` back.
- `~/.Trash` is on the home volume (other disks have their own `.Trashes`). A move from another volume (external disk) is a full copy and then a delete.
  Check the volume (`df <path>`), and for big data on other disks use a dated holding folder on the same disk instead.
- `rm` bypasses the Trash entirely, and so do `find -delete`, `rsync --delete` and `git clean -f`. They are
  deletions and need the dry run plus an explicit yes.
- If `mv` into `~/.Trash` fails with "Operation not permitted" (macOS privacy protection for the terminal), use a
  dated holding folder instead, or Finder's delete (`osascript -e 'tell application "Finder" to delete POSIX file "<abs path>"'`),
  which also keeps "Put Back".
- Never empty the Trash yourself. The user does that.

### Dry runs that paid off (examples)
- A new folder name `o2physics` next to an existing `O2Physics`: the same path on macOS's case-insensitive file
  system. The plan's guard caught it in the dry run, before anything moved.
- A staged move stopped at `rmdir` because Finder had left a `.DS_Store`. Thanks to the step order (checks before
  edits), nothing was half-edited, and the run resumed cleanly from that step.
- Trash instead of delete: 2.4 GB of old builds and 54 superseded result files went to the Trash or a holding folder.
  Nothing was lost, and the user decided when to free the space.

## Zones in practice
- Write the zone map (user-only, protected inputs, tracked work, playground) into CLAUDE.md with paths, and agree it.
- Everything you create lands in the playground by default. Promoting it to tracked work (`bin/`, `tests/`) needs the
  user's OK.
- Git makes the boundary visible: the user sees every edit to tracked work (`git status`, `git diff`) and can undo
  it; the playground is git-ignored, so experiments never leak into commits.
- Needing something outside the playground (installing, editing a config, writing next to data) means asking.

## Confidentiality
ALICE results are collaboration property until approved. Unapproved numbers and plots, AO2Ds and train outputs,
internal pages (twiki, JIRA, Hyperloop) and colleagues' code are not sent to external services (paste sites, online
converters, public issue trackers, public artifacts) and not pushed to public repositories without the user's OK.
Before a push to a public repo, check that no data files, result plots or internal numbers are in it (`git status`,
the `.gitignore`, a look at the diff).

## Git

- No git actions without an explicit yes, in any repo: no `init`, `commit`, `branch`, `push`, `tag`, `stash`,
  `checkout` that changes the tree, no `pull`/update of a checkout with local changes.
- Propose: which files, which message, why this split ("5 topic commits"), and what a reader of the repo gains from
  it (`analysis-design.md` §4). Track only useful files; never junk/legacy.
- Before reporting a bug found in a local checkout of a shared repo: compare with upstream; the local copy may be behind.
- Never commit local test-only patches (keep them as `.patch` files and named in the handover section).

## Acting with someone else's identity

Browser sessions with the owner's certificate, CI accounts, grid tokens:
- reading is fine; every state-changing action (save, submit, start/stop jobs, edit configurations, downloads, settings)
  needs its own explicit yes, describing exactly what will change. One yes never covers the next action.
- Stay on the agreed domains. Never log in as the owner anywhere.
- Know the side effects of the platform (in ALICE Hyperloop: an activated wagon with a successful test is automatically
  composed into a full train over the whole dataset).

## Passwords and secrets

Never type the owner's passwords or passphrases. Start the command in a terminal and let them type it. Never echo tokens.

## General machine safety (any user's computer)

These hold in every project, before you know anything about it. The user's laptop is also their mail, their thesis,
their other analyses and their only working environment. A broken shell setup or a deleted folder costs days.

### Look before you destroy
- Before any delete, overwrite or move, **look at the target** (`ls -la`, `du -sh`, `file`) and say what it is and how
  big it is. Confirm the current directory (`pwd`) before relative-path operations.
- Never run `rm -rf` on a path built from a variable that could be empty or unset (`rm -rf "$DIR/"*` with an empty `DIR`
  removes `/*`). Use `set -u` in scripts, guard with `[[ -n "$DIR" && -d "$DIR" ]]`, and prefer moving to the Trash.
- Run the non-destructive form first: `find … -print` before `find … -delete`, `rsync -n` before `rsync --delete`,
  `git clean -n` before `git clean -f`, `sed` without `-i` (shows the result) before `sed -i ''`.
- Don't overwrite files by accident: `cp -n` / `mv -n` (or check existence first); never `>` onto a file you didn't
  create; back up a config file (`cp f f.bak_<date>`) before editing it.
- Recursive permission changes (`chmod -R`, `chown -R`) and anything with `sudo`: don't. If it seems needed, explain
  why and let the user do it.
- Symlinks: know whether a command follows them (`rm -r link/` with a trailing slash, `cp -L`, `find -L`). Resolve
  them before deciding a target is safe.
- Quote every path (spaces and special characters are common on macOS: `Application Support`, iCloud folders).

### Don't change the system or the user's global setup
- No system or security settings, no `sudo`, no changes under `/usr`, `/opt`, `/Library`, `/System`.
- Shell startup files (`~/.zshrc`, `~/.bashrc`, `~/.bash_aliases`, `~/.profile`), `~/.gitconfig`, `~/.ssh/`,
  editor/IDE settings and tool configs in `~/.<tool>/`: read freely; change only with the user's yes, after a backup,
  showing the diff.
- **Package managers are global state.** `brew upgrade`, `brew install` of a dependency, `pip install` into the system
  or the ROOT Python, `conda update`: these can silently change the compiler, ROOT, Python or Boost that every build on
  the machine relies on. Ask first. Prefer project-local environments (venv) and name exactly what would change.
- Big shared software stacks (ROOT builds, aliBuild/alienv trees, O2/O2Physics builds, RooUnfold installs): never
  rebuild, clean or update them without asking. A rebuild can take hours, and a different version changes results.
- Don't change the default shell, `PATH` globally, login items, launch agents, cron jobs or scheduled tasks.

### Processes, resources, devices
- Only stop processes you started. Kill by PID or process group of your own job, never `killall` / `pkill` by name
  (the user may have their own ROOT or Python sessions running).
- Long or heavy jobs (full test suites, many-file runs, big builds with `-j`) in the background, with an estimate of
  time, CPU and disk, and a stated way to stop them. Don't fill the disk: check free space before large outputs.
- External drives and network mounts: no writes unless asked. Never format, partition or eject anything.

### Synced and backed-up places
- Folders synced by iCloud, Dropbox, OneDrive, CERNBox or Google Drive propagate deletions and mass changes to every
  device and to the cloud. Treat bulk operations there as high risk, and mention the sync.
- Moving huge temporary outputs into a synced folder can fill the user's cloud quota. Keep scratch data outside them.

### Git, the destructive commands
Even with a yes to "commit", these need their own explicit yes: `git reset --hard`, `git checkout -- <file>` /
`git restore` on modified files, `git clean -f`, `git stash drop`, `git branch -D`, `git push --force`, rebases of
pushed branches, deleting tags. Before any of them, show `git status` and what would be lost. Uncommitted work is the
most fragile thing on the machine.

### Network, downloads and secrets
- Don't run `curl … | bash` or execute downloaded scripts or binaries. Read a script before running it, keep
  downloads in their own folder, and download only with the user's OK (size and source stated).
- Never print, copy or upload secrets: tokens, certificates and keys (`~/.globus/`, grid proxies, `~/.ssh/`, `.env`,
  API keys). Don't put them into files that may be committed.
- Don't send the user's data, code or personal details to external services (paste sites, online converters, issue
  trackers) unless they ask.
- Shared resources such as grid quota, batch systems, CI minutes and shared disks: submitting jobs or using them at
  scale needs a yes, with the expected cost.

### When something went wrong anyway
Stop immediately. Don't try to repair it by further guessing. Report exactly what ran and what changed, and offer
recovery options: the Trash, Time Machine or another backup, git reflog, the `.bak` copy. Then let the user decide.
Write the lesson into CLAUDE.md or memory.

## Shell and tool traps

zsh vs bash, BSD tools (`sed -i ''`), case-insensitive file systems and many more: `pitfalls.md`.
