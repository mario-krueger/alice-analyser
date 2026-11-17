# Changelog

What changed for users between versions. Newest first.

## Unreleased

- Commit message form: brief imperative lowercase title without a final period; a body only when needed, with what,
  why and impact, never repeating the title (`references/analysis-design.md` §4).
- Communication: say each thing once, no repetition across summary, recap and closing (`references/collaboration.md`
  §4).

- Collaboration: "a yes covers only what the question named". Questions name the exact object and action; before
  asking, the agent lists everything the answer would set in motion and states the non-obvious consequences in the
  question ("This also changes: … It does not change: …"); separate decisions and self-picked defaults are asked on
  their own, never bundled; after the yes, one line on what it covers, and a new question if more turns out to be
  needed. Every answer option (button, numbered option, "yes") states in one crisp sentence what happens when it is
  chosen, to which objects, and where it stops, so that it allows only one reading (`SKILL.md` §1 and §2,
  `references/collaboration.md` §4, §7).

- Git: write for the reader who was not there. What makes a commit useful and what is annoying or useless (private
  step IDs and section numbers, unexplained hashes, dates of local events, commits that only document local
  state, diary text in tracked files). Step IDs are no longer recommended in commit messages
  (`references/analysis-design.md` §4, `SKILL.md`, `references/file-conventions.md`, `references/safety.md`).

- Collaboration: "ask for a decision only after taking them along": context and purpose in plain words, the
  decision in one sentence and why now, options with consequences, recommendation, what happens next; questions that
  stand alone; stop and re-explain on "what is X?" (`SKILL.md` §1, `references/collaboration.md` §4, §7).
- Verification: "think before you test". Checks are chosen by what a change can reach and run once each; reasoning
  may exclude what a change never executes, never what executed code computes. Fast-lane example in
  `references/verification.md` §5; the full rerun of published inputs stays mandatory inside the result path.

## 0.1.0

First public version.
- `SKILL.md`: scientific-coworker role; three analysis stages; rigour and momentum; what the agent may do without
  asking, with a yes, never; reproducibility; taking the owner along; step loop with predictions and diff review;
  zones, dry runs and Trash; verification; project structure and notebook.
- References for toolbox, project structure, file conventions, analysis design (concept phase, from macros to a
  framework), collaboration, verification, safety, O2Physics, grid and Hyperloop (incl. finding data and anchored MC),
  offline corrections, plotting, Python and ROOT, pitfalls, links, library development.
- Templates (notebook, CLAUDE.md, study README, dry-run plan script, .gitignore) and scripts (`root_filecmp.C`,
  `check_tools.sh`).
- Version check: once per session the agent compares its version with the latest release and, if outdated, tells
  the user in one line how to update.
