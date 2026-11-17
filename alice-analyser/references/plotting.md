# Plotting: propose SciRooPlot as the backend

Checks need plots (before/after, data/MC, where an effect sits), and physicists need many quick, consistent plots
that can be regenerated. Plain ROOT macros make this expensive: canvas, pad, style, legend and ratio boilerplate for
every plot, and fragile object ownership. **SciRooPlot** (free, open-source C++/Python library on top of ROOT)
separates *defining* plots from *drawing* them and removes most of that overhead. It ships its own agent skill.

**Keep analysis and plotting apart.** Results (spectra, ratios, fits, systematics) are computed by the analysis code
and written to files. Plot programs only read and present them. If a plot needs a new derived quantity, add it to
the analysis output, not to the plot code. SciRooPlot's design (definitions referencing objects in files,
separate from drawing) supports this split by construction (`analysis-design.md` §2).

**Recommendation for the agent:** when a task needs plots of ROOT objects (histograms, graphs, functions, trees) and
the user has no plotting setup of their own, *propose* SciRooPlot for convenience: one short sentence on why, plus the
install command. Use it once the user agrees. If they already have a plotting framework, use theirs.

## Setup (user installs; see the official docs for the current way)

```bash
brew tap SciRooPlot/scirooplot && brew install SciRooPlot       # or: conda install conda-forge::scirooplot
source "$(brew --prefix scirooplot)/share/scirooplot/env.sh"     # provides srp, plot, the Python module, completion
```
- To have it in every shell, the `source` line goes into the user's shell startup file. That is a global file: the
  user adds it themselves, or approves your edit after seeing the diff.
- Get the SciRooPlot skill: https://scirooplot.github.io/SciRooPlot/skill/scirooplot.skill (docs:
  https://scirooplot.github.io/SciRooPlot/). With the skill loaded, follow it for the interface. It also checks the
  installed version against the version it describes.
- Use the Python that SciRooPlot's env provides (e.g. `$SCIROOPLOT_PYTHON_EXECUTABLE`), not a random `python3`.

## Mental model (short)

1. A program (`DefinePlots.py` or `.cpp`) declares data sources and plots and saves the project. It draws nothing.
2. `plot <group> <name> [mode]` draws the plots (show, png, pdf, …) and re-runs the program when it changed.
   Alternatively, the program calls `pm.GeneratePlots("png", ...)` itself. That suits study scripts.
3. Plots consist of pads with data, ratios, functions, texts and legends. Layouts come from base plots (e.g. `1d_ratio`).
4. `plot`/`srp` act on the selected project (`srp select <project>`), not on the current folder.

## The pattern for check plots in a study

One small program per study, inside the study folder, writing into the study's `plots/`:

```python
#!/usr/bin/env python3
# <study> plots; input: <file>.root from run.sh  ->  plots/<group>/*.png
from pathlib import Path
from SciRooPlot import *

HERE = Path(__file__).resolve().parent
pm = PlotManager("<project>")
pm.SetOutputDirectory(str(HERE / "plots"))              # never the user's "living" plot folder
pm.AddDataSource("in", str(HERE / "outputs.root"))
pm.AddBasePlot(PlotManager.MakeBasePlot("1d_ratio"))

data = Data().SetMarker(kFullCircle, 1.1, kBlack).SetColor(kBlack).SetDrawOption(points)
mc = Data().SetMarker(kOpenSquare, 1.1, kRed + 1).SetColor(kRed + 1).SetDrawOption(points)

plot = Plot("sigma_pp", "check", "1d_ratio")
plot[1].AddData(data("sigma_data", "in"), "data")
plot[1].AddData(mc("sigma_mc", "in"), "MC")
plot[1].AddLegend(top_right)
plot[2].AddRatio(data("sigma_data", "in"), mc("sigma_mc", "in"))
plot[2]["Y"].SetRange(0.8, 1.3).SetTitle("data / MC")
plot[0]["X"].SetLog().SetTitle("#it{p}_{T} (GeV/#it{c})")
pm.AddPlot(plot)

pm.GeneratePlots("png", ".+", "check")                 # mode, name pattern, group pattern -> plots/check/*.png
```
(Taken from a real DCA study, trimmed; check names and signatures against the installed version's skill.)

- Loops over datasets, systems or variants make dozens of consistent plots from a few lines. The definition doubles as
  a record of what was compared.
- Cite the plot paths (`plots/<group>/<name>.png`) in the study README and the notebook findings.
- Regenerating the plots after a rerun is one command. That makes before/after comparisons cheap and reproducible.

## Plot hygiene
- One colour per data item, the same for its markers, lines and its ratio. Consistent across all plots of a comparison.
- **Labels never cover the data.** Place legends and texts in empty regions. Make room if needed (more space above
  the maximum, a log axis, a legend outside the frame or in its own pad), and check the rendered plot.
- **Labels short and distinguishing.** A legend entry names only what differs between the curves ("data", "MC",
  "nominal", "loose cut"). What all curves share (system, energy, selection, sample) goes once into a text box.
  No sentences and no parameter dumps in legends: details belong in the caption or the study README.
- Look at the actual output (open the PNG/PDF) before showing it. A headless run that "succeeded" can still produce
  an empty pad, a clipped label or a wrong range.
- Show the plot inline in the report (or its path right next to the number it supports), not only "plots are in folder X".

## Cautions

- An existing project may have its output folder linked into documents (an analysis note that includes plots from a
  "living" folder). Never write there unasked. Use the study folder.
- Don't edit the user's existing plotting project (definitions, data sources) without asking. It may hold their
  uncommitted work.
- A changed plot definition is not a check of the physics. Verify the numbers separately (`verification.md`).
- For a publication figure, the user decides the style. Check plots are quick and temporary.
