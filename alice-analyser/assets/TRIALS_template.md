# <Project>: trial log

What was tried, how it was tested, and what came out, kept for good. Studies are deleted and setups change; this
file keeps the conclusions. Read it before proposing an idea; use it at the wrap-up to state what was tested.

Rules:
- One entry per closed trial, **null results especially**. Written in the words of the problem, not the code
  (no function names, step IDs or folder names that will vanish), so it reads correctly years later.
- Enough to judge how strong the conclusion is, not to reproduce it.
- Entries are never deleted. An outdated one gets `→ superseded by T<n>`.
- IDs `T1, T2, …` stay fixed. Entries grouped by topic; the overview table lists them all.

Verdicts: ✅ adopted · ❌ does not work · ⚠️ inconclusive · ⏸ blocked / not tested

## Overview
| id | question | verdict | topic |
|---|---|---|---|
| T1 | Can a tighter DCA cut replace the feed-down correction? | ❌ | selections |

---

## Selections

### T1  Can a tighter DCA cut replace the feed-down correction?   ❌  (<YYYY-MM>)
Attempt: DCAxy < 0.05 cm instead of the pT-dependent cut.
Test:    secondary fraction in MC (general-purpose MC, 2M events), pT 0.5–5 GeV.
Result:  8% → 5%, flat in pT; 12% fewer primaries.
Verdict: not negligible, so the correction stays; the cut only costs statistics.
Valid while: MC describes the DCA tails (checked against data within 10%).
Revisit if: a data-driven DCA template fit becomes available.
