# Developing a library or tool that other people use

For libraries other people depend on (for example a plotting library on top of ROOT), often written by one
maintainer and extended with an agent's help in the maintainer's style, with the maintainer reviewing. Users' code
must keep working, and outputs must stay the same unless a change is announced.

## The owner's baseline is the reference

The years of code the owner wrote before the agent joined set the conventions: the fluent setter interface, how
errors are reported, the naming, the folder layout. New code follows them. That kept the library coherent and kept
the owner able to review every change. Read enough of the existing code before adding to it to know its idioms.
Copy the closest existing feature's structure rather than inventing a new one.

## Tests: one guarantee per file, against an independent reference

- **One folder per feature area, one file per guarantee.** The file name says what is guaranteed (`log_axes`,
  `stored_ranges`, `robust_frames`). The docstring states the guarantee, the cases, the reference and what it covers.
- **The reference does not come from the code under test.** Use plain ROOT drawing the same object, an invariant,
  or the values that were requested. Comparing the code with itself proves nothing.
- **Case lists over the whole interface.** Cover every data kind × every relevant option. Shared lists (`DATA_KINDS`,
  `VARIANTS`) mean a kind added there is tested everywhere. A fast run covers each value once plus important pairs.
  A full run (`SRP_TESTS_FULL=1`, weekly in CI) takes the whole list.
- **A bug found later adds a case to the file that should have caught it**, with a short text saying what it checks.
  Over time the suite becomes the record of every mistake that cannot happen again.
- Exit codes: 0 pass, 1 fail, 77 skipped (cannot run here); CTest reports 77 as a skip when the test has the
  `SKIP_RETURN_CODE 77` property set.
- Long or expensive checks (random interface fuzzing, repeated runs for leaks, sanitizer builds) live in an `extended/`
  set. Diagnostic tools that are never run by CTest live in `tools/`: pixel comparison of two builds, speed, memory,
  call counts.

## Every user-visible change is documented as a migration step

An `api-changes.md` with one section per release. Each change is a table row `old | new | kind | action`, where kind
is one of:
- *renamed / removed / signature*: code breaks and the user has to search for the old name;
- *default / behaviour*: code still runs but the **output differs**. These are the dangerous ones and must be
  listed precisely;
- *input validation*: input that used to be accepted is now refused (warned about and ignored, or an exception);
- *file format*, *CLI*, *build*.

Writing this table while making the change forces the question "who notices this, and what must they do?". If you
cannot fill in the *action* column, the change is not ready.

## Behaviour on bad input

Decide the policy once and apply it everywhere. In this library: an invalid value is warned about and ignored, and
the previous value stays. A message names the data it concerns, not just the plot. An unreadable input gets one
message, not a cascade. Silently drawing something wrong is the worst outcome. A warning plus "not drawn" is better
than a wrong picture.

## Commits and releases

- Small commits whose subject says the behaviour in plain words, lowercase, no prefix noise ("warn and ignore invalid
  dimensions, legend symbols and data entries where set").
- Before a release: the full and extended test runs. The interface-change section is completed. The version number
  is updated in every place that names it (packaging recipes, docs, the agent skill).
- Credit honestly. A `CONTRIBUTORS.md` line saying the AI assistant co-developed code, docs and tests with the
  maintainer.

## Ship an agent skill with the library

The library publishes its own skill: a mental model, an API reference and common pitfalls, plus a version check.
The skill tells the agent to compare the installed version with the version it describes. If the installed one is
older, the agent asks the user to update. If it is newer, the skill is outdated, and the agent points to the current
skill. Keep the skill in the repo and regenerate its API reference from the code, so it cannot drift.
The frontmatter must be strict YAML: quote the `description` if it contains `: ` (lenient parsers accept it, GitHub
and other tools do not), and parse it in CI.
