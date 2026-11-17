#!/usr/bin/env bash
# <STEP> (<date>): <one line: what moves/changes where>.
# DRY RUN by default (prints every action); run with --do to execute.
# Not touched: <list the protected places explicitly>.
set -euo pipefail
WS="$HOME/workspace/PROJECT"          # placeholders are CAPS: replace them
CHK="$WS/workbench/DATE_TOPIC/STEP"     # check outputs (manifests, logs) go here
DO=0; [[ "${1:-}" == "--do" ]] && DO=1
run() { echo "  \$ $*"; if [[ $DO -eq 1 ]]; then "$@"; fi; }
cd "$WS"

# preconditions: stop before anything happens if the world is not as planned
SRC="SOURCE"; DST="TARGET"
[[ -e "$SRC" ]] || { echo "$SRC missing, stop"; exit 1; }
[[ -e "$DST" ]] && { echo "$DST exists, stop"; exit 1; }

echo "== 0. before: md5 manifest of everything that moves"
if [[ $DO -eq 1 ]]; then
  mkdir -p "$CHK"
  (find "$SRC" -type f ! -name .DS_Store -print0 | sort -z | xargs -0 md5 -r) > "$CHK/before.md5"
fi

echo "== 1. move (same disk: rename only, keeps dates)"
run mv "$SRC" "$DST"

echo "== 2. check: moved files bit-identical (before any edit)"
if [[ $DO -eq 1 ]]; then
  (find "$DST" -type f ! -name .DS_Store -print0 | sort -z | xargs -0 md5 -r) > "$CHK/after.md5"
  # map old paths to new ones in before.md5 if needed, then:
  diff -q <(awk '{print $1}' "$CHK/before.md5") <(awk '{print $1}' "$CHK/after.md5") \
    && echo "  OK: $(wc -l < "$CHK/after.md5" | tr -d ' ') files identical" \
    || { echo "  MISMATCH, stop"; exit 1; }
fi

echo "== 3. path updates (show counts in the dry run, apply on --do)"
# for f in ...; do n=$(grep -c '<old>' "$f" || true); echo "    $f: $n lines"; [[ $DO -eq 1 ]] && sed -i '' 's#<old>#<new>#g' "$f"; done

echo "== 4. checks after --do (run and report each)"
echo "  a) md5 manifest identical (done in 2)"
echo "  b) no stale '<old>' path left (grep), except dated history notes"
echo "  c) tools build with no work; smoke run bit-identical to the reference"
echo "  d) git status in every repo exactly as expected"
[[ $DO -eq 1 ]] && echo "done." || echo "dry run only; run with --do to execute."
