# Documentation and pointers

Read the official documentation before guessing how the framework behaves. Code beats docs where they disagree:
check the O2Physics source (`upstream/master`).

## O2 analysis framework (https://aliceo2group.github.io/analysis-framework/docs/)

| need | page |
|---|---|
| install O2/O2Physics, grid certificate | `gettingstarted/installing.html`, `gettingstarted/certificate.html` |
| repository structure, contributing (PR workflow, formatting) | `gettingstarted/theo2physicsrepo.html`, `gettingstarted/contributingtocode.html` |
| framework concepts: tables, subscribing, filters/partitions, new tables, combinations, CCDB | `basics-tasks/` (Introduction, IntroductionTables, SubscribingToData, FilteringPartitioning, CreatingNewCollections, CombiningData, TheCCDB) |
| running: downloading AO2Ds, setting up, json configs, options | `basics-usage/` (DownloadingFiles, SettingUp, JsonConfigs, RunningAnalysis) |
| event selection, multiplicity/centrality, PID, track selection/propagation | `analysis-tools/` (EventSelection, MultiplicityAndCentralitySelection, PID, TrackSelection) |
| Hyperloop: user docs, notifications, fair-usage policy, changes for Run 2 LEGO-train users | `hyperloop/userdocumentation.html`, `hyperloop/notifications.html`, `hyperloop/hyperlooppolicy.html`, `hyperloop/legoexpert.html` |
| track-to-collision association, event mixing, ML, PWG specifics (e.g. PWGLF) | `advanced-specifics/` |
| tutorials (tasks, histogram registry, tables, MC data, CCDB, multi-process) | `tutorials/` |
| data model reference: AO2D tables, helper-task tables, PWG tables, joins/iterators | `datamodel/ao2dTables.html`, `datamodel/helperTaskTables.html`, `datamodel/pwgTables.html`, `datamodel/joinsAndIterators.html` |
| dependency finder (which helper tasks produce a table), O2 linter | `tools/dependencyFinder.html`, `tools/o2linter.html` |
| FAQ, troubleshooting, glossary | `faq/`, `troubleshooting/`, `glossary/` |

All paths are relative to the docs base URL above.

## Other sources

- **Hyperloop** (alimonitor.cern.ch/hyperloop): datasets, analyses, trains. Needs the user's certificate in the browser.
  It is the source of truth for which datasets and conversions exist.
- **O2Physics on GitHub** (AliceO2Group/O2Physics): code, PRs, CI; `.github/workflows/` shows what CI checks.
- **O2 data model code** (AliceO2Group/AliceO2, `Framework/Core/include/Framework/AnalysisDataModel.h`) for exact
  column meanings; the AOD producer for how flags are set.
- **ROOT** (root.cern/doc), **uproot/awkward** (scikit-hep docs), **RooUnfold** (gitlab.cern.ch RooUnfold),
  **SciRooPlot** (scirooplot.github.io/SciRooPlot).
- **Internal pages** (twiki, JIRA, bookkeeping, MC production pages) may need SSO. Don't log in as the user. Ask
  them to open the page or save it into `share/`, then read the saved copy. Twiki lists can be outdated: cross-check
  with Hyperloop.
