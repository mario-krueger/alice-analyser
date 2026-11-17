#!/usr/bin/env bash
# repository checks for the alice-analyser skill, then build dist/alice-analyser.skill (a zip of the skill folder).
#   scripts/check.sh            checks + build
#   scripts/check.sh --tag vX   also require the tag to match VERSION (used by the release workflow)
# exit code 0 only if every check passes.
set -uo pipefail
cd "$(dirname "$0")/.."
S=alice-analyser; fail=0
ok()  { echo "  ok    $*"; }
bad() { echo "  FAIL  $*"; fail=1; }

echo "== frontmatter"
head -1 "$S/SKILL.md" | grep -qx -- '---' && ok "frontmatter starts" || bad "SKILL.md must start with ---"
name=$(sed -n 's/^name: //p' "$S/SKILL.md" | head -1)
[[ "$name" == "$S" ]] && ok "name: $name" || bad "name is '$name', expected '$S'"
desc=$(sed -n 's/^description: //p' "$S/SKILL.md" | head -1)
[[ -n "$desc" && ${#desc} -le 1024 ]] && ok "description: ${#desc} characters" || bad "description missing or longer than 1024 (${#desc})"
# parse the frontmatter as strict yaml (github and other tools reject what lenient parsers accept)
if python3 -c 'import yaml' 2>/dev/null; then
  python3 -c '
import sys, yaml
m = yaml.safe_load(open(sys.argv[1]).read().split("---")[1])
assert isinstance(m, dict) and m.get("name") and m.get("description")' "$S/SKILL.md" 2>/dev/null \
    && ok "frontmatter parses as yaml" || bad "frontmatter is not valid yaml (quote values that contain ': ')"
else bad "PyYAML missing: cannot parse the frontmatter (pip install pyyaml)"; fi
lines=$(wc -l < "$S/SKILL.md" | tr -d ' ')
[[ $lines -le 500 ]] && ok "SKILL.md: $lines lines" || bad "SKILL.md: $lines lines (> 500)"

echo "== links between skill files"
missing=0
# reference files named in backticks, e.g. `references/safety.md` or `safety.md` (whole names, digits allowed)
while IFS= read -r ref; do
  [[ -e "$S/references/$ref" ]] || { bad "referenced but missing: references/$ref"; missing=1; }
done < <(grep -rhoE '`(references/)?[a-z0-9-]+\.md`' "$S" | tr -d '`' | sed 's#^references/##' | sort -u |
         grep -vxE 'plan\.md|braindump\.md|notes\.md|api-changes\.md|working-rules\.md')
for p in $(grep -rhoE '(assets|scripts)/[A-Za-z_.-]+' "$S/SKILL.md" | sort -u); do
  [[ -e "$S/$p" ]] || { bad "referenced but missing: $p"; missing=1; }
done
[[ $missing -eq 0 ]] && ok "all referenced files exist"

echo "== scripts"
for f in "$S"/scripts/*.sh "$S"/assets/*.sh scripts/*.sh; do bash -n "$f" && ok "bash -n $f" || bad "syntax: $f"; done

echo "== privacy scan (personal paths, emails, run/dataset identifiers)"
hits=$(grep -rnE '/Users/[A-Za-z]|/home/[a-z]+/|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[a-z]{2,}|\bLHC[0-9]{2}[a-z]{1,2}[0-9]?\b|\b5[0-9]{5}\b' \
       "$S" README.md llms.txt CHANGELOG.md | grep -v 'LHC<' || true)
[[ -z "$hits" ]] && ok "no personal paths, emails or run/dataset identifiers" || { bad "privacy scan hits:"; echo "$hits" | sed 's/^/        /'; }

if [[ "${1:-}" == --tag ]]; then
  echo "== version"
  [[ "${2:-}" == "v$(cat VERSION)" ]] && ok "tag ${2} matches VERSION" || bad "tag '${2:-}' does not match VERSION $(cat VERSION)"
fi
n=$(grep -o "alice-analyser $(cat VERSION)\*\*" "$S/SKILL.md" | wc -l | tr -d ' '); c=$(grep -c "newer than $(cat VERSION)," "$S/SKILL.md")
[[ $n -eq 1 && $c -eq 1 ]] && ok "SKILL.md states version $(cat VERSION) (header and version check)" || bad "SKILL.md version does not match VERSION $(cat VERSION) (header $n, check $c)"
grep -q "^## $(cat VERSION)$" CHANGELOG.md && ok "CHANGELOG has an entry for $(cat VERSION)" || bad "CHANGELOG has no entry for $(cat VERSION)"

echo "== build"
rm -rf dist; mkdir -p dist
zip -qr "dist/$S.skill" "$S" -x '*.DS_Store' -x '*_C.so' -x '*_C.d' -x '*.pcm' && ok "dist/$S.skill ($(du -k "dist/$S.skill" | cut -f1) kB, $(unzip -l "dist/$S.skill" | tail -1 | awk '{print $2}') files)" || bad "zip failed"

[[ $fail -eq 0 ]] && echo "all checks passed" || echo "CHECKS FAILED"
exit $fail
