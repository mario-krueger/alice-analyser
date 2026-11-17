# Grid, data and Hyperloop: setup, navigation, downloads, steering

How an ALICE analyser and the agent work with AliEn (the grid catalogue) and Hyperloop (the train system), and which
steps only the human can do. UI details are as seen in November 2026. Hyperloop's interface changes, so read the page
in front of you rather than trusting a remembered layout.

## Contents
1. What the user sets up (once)
2. Who does what
3. Grid token
4. Navigating the catalogue
5. Getting files: download vs stream
6. Hyperloop: reading
7. Hyperloop: steering (tests, wagons, trains)
8. Run 2 / Run 1 converted data
9. Finding data and anchored MC fast

---

## 1. What the user sets up (once)

The agent cannot (and must not) do these. Tell the user what is missing and let them do it:
- **CERN account with ALICE membership and a grid certificate**: `usercert.pem` + an encrypted `userkey.pem` in
  `~/.globus/`, registered with the ALICE VO.
- **O2Physics built locally** with aliBuild and usable via `alienv` (the agent may run `alienv setenv … -c <cmd>` to
  work inside it, but never rebuilds the stack unasked).
- **For Hyperloop / alimonitor in a browser**: the certificate imported into the browser or OS keychain (as `.p12`),
  plus the CERN trust anchors (CERN Root CA, CERN Grid CA). Hyperloop authenticates by **client certificate**.
  **Chrome is the way:** browsers built into agent apps cannot present the grid client certificate, so Hyperloop and
  alimonitor are used only through the user's own Chrome with the Claude in Chrome extension. Don't try or propose
  the built-in browser for them. The user should restrict the extension's site access to
  `alimonitor.cern.ch`.
- **Membership in a Hyperloop analysis** (registered within a PWG, with analysers listed). Creating or joining an
  analysis is done by the user.

## 2. Who does what

| action | agent | user |
|---|---|---|
| read catalogue (`alien.py ls/find`), Hyperloop pages, train results, dataset pages | ✅ freely | |
| type the grid passphrase, log in anywhere (SSO, certificate choice) | ❌ never | ✅ |
| download files | small samples into the playground within the agreed disk budget (size stated); larger ones after an explicit yes | sets the budget, approves large ones |
| anything state-changing on Hyperloop: save a wagon, change configuration, run a test, activate/deactivate, add datasets, start/stop trains | only after an explicit yes **for that specific action**, each time | approves |
| leave alimonitor for other sites (JIRA, twiki, …) with the user's identity | ❌ (ask the user to open/save the page) | ✅ |

The browser acts with the user's personal grid identity. Mistakes cost grid resources and are visible to the
collaboration. Describe exactly what a click will change before asking.

## 3. Grid token

- `alien-token-init` creates a token from the certificate. Check it with `alien-token-info`.
- With an encrypted key and some OpenSSL versions in alienv, the stock `alien-token-init` fails **silently**
  ("INVALID ; INVALID", no passphrase prompt). A fix that works: a small wrapper that asks for the
  passphrase with a hidden prompt (nothing stored) and hands it to the SSL loader, then calls alienpy's token init.
- The agent **starts** the command in a terminal the user can see and type into; the user types the passphrase.
- Tools that need the grid check the token first and print the exact command to run if it is missing.

## 4. Navigating the catalogue

`alien.py` (inside alienv):
```bash
alien.py ls /alice/data/<year>/<period>/                 # periods → runs → passes
alien.py ls /alice/data/<year>/<period>/<run>/
alien.py find /alice/sim/<year>/<production>/<…>/<run> AO2D.root   # all AO2Ds below a folder
alien.py cp alien:///alice/.../AO2D.root file:./AO2D.root  # one file
```
Layout (typical): data `/alice/data/<year>/<period>/<run>/<pass>/…`, MC `/alice/sim/<year>/<production>/<…>/<run>/…`.
- Full passes are often cleaned up. Look for sibling folders such as `*_sampled`, `*_skimmed` or `Thinner/`.
- Anchored MC: find the production anchored to your data pass (Hyperloop dataset descriptions and the MC production
  pages say which period/pass). Pick the same run in data and MC for local tests.
- Cache the catalogue listing locally (a `catalogue.txt` per sample) so reruns don't hit the catalogue again.

## 5. Getting files: download vs stream

- **State size and disk budget first**: AO2Ds are ~0.1–2 GB each; MC files are often larger.
- **Download** with `alien.py cp` (≈ 15 MB/s seen). **Stream** (`alien://` paths in the input list; DPL reads them)
  saves disk, but the catalogue picks the replica by "closeness", not speed: one MC file streamed at 40 kB/s (hours).
  Rule of thumb: stream small data files, download big MC files.
- Sample tool behaviour that worked: `fetch <name> <alien-dir> -n N [--random] [--stream]` → files in
  `input/<name>/`, a list `input/<name>.txt` for the run script; random picks with a fixed seed (reruns extend the same
  sample); existing files skipped; provenance (`sources.txt`) per file.
- For quick tests, cut the first few dataframes of one file into a cached slice. Develop on that, and use whole files
  for physics checks.
- Single test inputs of a production can also come from a train's *test output* on Hyperloop (train → test results →
  output → `AO2D.root`). Downloading needs a yes.

## 6. Hyperloop: reading

Useful pages (alimonitor.cern.ch/hyperloop/…, as seen 2026-11):
- **Dataset page** (`view-dataset/<id>`): content (periods, passes, runs), anchoring for MC, size, and the
  **automatic train composition schedule** (e.g. "twice daily 07:00/19:00"). Record the schedule of every dataset you use.
- **Analysis page**: the datasets attached to the analysis and its **wagons** (task + configuration per dataset), with
  their state (active/inactive) and test status.
- **Train results**: per train the output files, logs, run time, memory and test results.
- The dataset list (filter by type, e.g. RUN2 for converted data) is the source of truth for which conversions and
  productions exist. Twikis and old notes can be outdated.

Record what you read (dataset ids, schedules, wagon states) in the notebook with the date. The pages change.

## 7. Hyperloop: steering (tests, wagons, trains)

The essential trap: **an activated wagon whose test succeeds is picked up by the automatic train composition at the
dataset's next scheduled time and runs over the full dataset.** That means grid resources, and a train that
everybody sees.
- For "just a test" (quick statistics, checking that the task runs on a dataset), keep the wagon **deactivated**,
  or deactivate it right after the test, unless a full train is intended.
- Every activation, deactivation, configuration change and test start: describe it, get the user's yes, then do it.
  One yes covers one action.
- Before tests: the code version must be in a tag/release that Hyperloop builds (local commits are not available
  there). The order is: PR merged → tag contains it → wagon tests.
- A minimal test per dataset (task runs, tables present, metadata and axes right, no fatal) before any physics campaign.
- Collect QA from the tests (cut flows, data/MC comparisons, response matrices) into the notebook. Decide defaults
  from them, then run full trains.
- Before touching any existing wagon of a shared analysis: check who owns it and leave colleagues' wagons alone.

## 8. Run 2 / Run 1 converted data

- Converted Run 1/2 datasets exist on Hyperloop (type RUN2), sometimes in several conversion versions (`_v2`).
  Check which conversion matches your MC, and check the flags. Background flagging was wrong in some MC conversions,
  so measure the flag on a real file rather than trusting the description.
- They need the Run 2 service variants (`*-run2` event selection / propagation), data-model converters for old table
  versions, and Run 1/2 trigger paths (kINT7, INT1). Wrong paths select ~0 events silently.

## 9. Finding data and anchored MC fast

The questions in every new analysis: which data exist for my system/energy/year, which reconstruction pass is newest,
which MC is anchored to it, and which runs do they share? A route that works quickly:

1. **Ask the user first** for what they already know: system, energy, period(s), the pass the PWG recommends, MC
   productions colleagues use, the Hyperloop analysis they belong to. Two sentences from them can save an hour.
2. **Hyperloop dataset list** (source of truth): filter by type (Run 3 data, MC, RUN2 for converted Run 1/2) and search
   by period (`LHC<yy><x>`), production or system. The dataset page shows periods, passes, runs, size, and
   for MC the anchoring in its description. Name patterns help: data `LHC<yy><period>_pass<N>[_Thin|_small|_medium|_MinBias]`;
   general-purpose MC productions are named like `LHC<yy><letter><digit>[letter]`, and
   variants carry suffixes (`_small`, `_gp`, `_fix`, `_v2` for re-conversions).
3. **The file itself is the ground truth.** AO2D `metaData` carries `LPMProductionTag`, `RecoPassName`,
   `AnchorProduction`, `AnchorPassName` and `DataType`. Read them from one downloaded or streamed file to confirm the
   anchoring and the pass before relying on a description.
4. **Grid catalogue** for runs: `alien.py ls /alice/data/<year>/<period>/` and `alien.py ls /alice/sim/<year>/<prod>/`
   list the runs. Pick a run that exists in both, for a matched local data + MC test.
5. **Several candidates?** Rule that worked: newest pass + newest general-purpose MC anchored to it (PYTHIA as
   nominal, other generators as alternatives/systematics). Deviations can come from the pass or the MC version, not
   only your code: compare across productions before concluding.
6. **Record it immediately** in a living notebook table: system → chosen data → chosen MC → alternatives → dataset
   links → tested (which run, which section) → Hyperloop schedule. Mark what is confirmed (file metadata, test run)
   vs only read in a description.

Pitfalls: twiki/production lists can be outdated (newer conversions exist under other names); MC descriptions can
contain typos (a "pass2" that is really pass3, according to the conversion list); some pages (bookkeeping, JIRA, MC
production pages) need SSO, so ask the user to open or save them; full passes get cleaned up from the grid (use the
`_sampled`/`Thinner` siblings).
