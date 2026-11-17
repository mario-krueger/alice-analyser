# Changelog

What changed for users between versions. Newest first.

## Unreleased

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
