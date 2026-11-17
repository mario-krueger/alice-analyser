#!/usr/bin/env bash
# report which tools of the usual ALICE-analysis toolbox are present (read only: installs nothing, changes nothing).
#   bash check_tools.sh
# then ask the user to install what is missing and needed for the task (exact commands in references/toolbox.md).
set -uo pipefail

ver() { # ver <cmd> <version args...>: print first line of the version output
  local c="$1"; shift
  if command -v "$c" >/dev/null 2>&1; then
    printf "  %-16s ok       %s\n" "$c" "$("$c" "$@" 2>&1 | head -1 | cut -c1-70)"
  else
    printf "  %-16s MISSING\n" "$c"
  fi
}

echo "== base"
ver git --version
ver python3 --version
ver cmake --version
ver brew --version
xcode-select -p >/dev/null 2>&1 && printf "  %-16s ok       %s\n" "xcode-clt" "$(xcode-select -p)" || printf "  %-16s MISSING\n" "xcode-clt"

echo "== root / plotting / unfolding"
ver root-config --version
command -v root-config >/dev/null 2>&1 || echo "                   (installed ROOT often appears only after: source <root>/bin/thisroot.sh)"
(cd / && python3 -c 'import ROOT') >/dev/null 2>&1 && printf "  %-16s ok\n" "pyroot(python3)" || printf "  %-16s not importable with this python3 (may live in another interpreter)\n" "pyroot(python3)"
ver srp info
command -v srp >/dev/null 2>&1 || echo "                   (SciRooPlot appears only after sourcing its env.sh)"
[[ -n "${RooUnfold_DIR:-}" ]] && printf "  %-16s %s\n" "RooUnfold_DIR" "$RooUnfold_DIR" || printf "  %-16s (not set; fine if passed to cmake explicitly)\n" "RooUnfold_DIR"

echo "== alice / o2"
ver aliBuild version
ver alienv --version
[[ -d "$HOME/.globus" ]] && printf "  %-16s %s\n" "~/.globus" "$(ls "$HOME/.globus" 2>/dev/null | tr '\n' ' ')" || printf "  %-16s MISSING (grid certificate)\n" "~/.globus"
echo "  (alien.py, o2-analysis-*, clang-tidy of alisw live inside alienv: check with 'alienv list' / 'alienv q')"

echo "== o2 locations (defaults of aliBuild; confirm with the user)"
SW="${ALIBUILD_WORK_DIR:-$HOME/alice/sw}"; SW="${SW%/}"
[[ -d "$SW" ]] && printf "  %-16s %s\n" "work dir" "$SW" || printf "  %-16s not found at %s\n" "work dir" "$SW"
for d in "$HOME/alice/O2Physics" "${O2P_SRC:-}"; do
  [[ -n "$d" && -d "$d/.git" ]] && printf "  %-16s %s  (branch %s, %s changed files)\n" "O2Physics src" "$d" \
    "$(git -C "$d" rev-parse --abbrev-ref HEAD 2>/dev/null)" "$(git -C "$d" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
done
B="$SW/BUILD/O2Physics-latest/O2Physics"
[[ -f "$B/CMakeCache.txt" ]] && printf "  %-16s %s\n" "O2Physics build" "$B" || printf "  %-16s not found at %s\n" "O2Physics build" "$B"
for a in "$SW"/*_*/O2Physics; do [[ -d "$a" ]] && printf "  %-16s %s: %s\n" "installed" "${a#"$SW"/}" "$(ls "$a" | tr '\n' ' ')"; done   # load one with alienv setenv O2Physics/<version>
echo "  token: run inside alienv:  alienv setenv O2Physics/latest -c alien-token-info"

echo "== code quality / github"
ver pre-commit --version
ver clang-format --version
ver clang-tidy --version
ver gh --version
command -v gh >/dev/null 2>&1 && { gh auth status >/dev/null 2>&1 && echo "  gh               logged in" || echo "  gh               not logged in"; }

echo "== documents"
ver pdftotext -v
ver latexmk --version
ver pdflatex --version

echo "== shell"
printf "  %-16s %s\n" "login shell" "${SHELL:-?}"
sed --version >/dev/null 2>&1 && echo "  sed              GNU" || echo "  sed              BSD (use sed -i '')"
