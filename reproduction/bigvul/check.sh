#!/usr/bin/env bash
# Run one reproduction and print the lines that decide it.
#
#   ./check.sh 178202
#
# This prints; it does not judge. The decision is yours, and ../README.md says what to
# weigh: the sanitizer report and which side it fired on, the negative control staying
# identical, and whether the fault is attributed to the labelled function or to something
# it calls.
set -u
cd "$(dirname "$0")"
TAG=${1:?usage: $0 <tag from images.csv>}
REPO=vulvalidate/bigvul-repro
LOG=$(mktemp)
trap 'rm -f "$LOG"' EXIT

echo "=== what the index says about $TAG ==="
head -1 images.csv
grep "^$TAG," images.csv || { echo "no such tag in images.csv"; exit 2; }

echo
echo "=== what this project recorded ==="
docker run --rm --entrypoint cat "$REPO:$TAG" /repro/dynamic_evidence/EXPECTED.json \
  2>/dev/null || echo "(no EXPECTED.json in this image)"

echo
echo "=== running it ==="
docker run --rm --network none "$REPO:$TAG" > "$LOG" 2>&1
rc=$?
echo "container exit $rc, $(wc -l < "$LOG") lines"

echo
echo "=== sanitizer reports (note: MSan and TSan print WARNING, not ERROR) ==="
grep -nE '(ERROR|WARNING): (Address|Memory|Undefined|Thread|Leak)Sanitizer|runtime error:' \
  "$LOG" || echo "  none -- this case's oracle is a printed value or a count"

echo
echo "=== per-side exit codes ==="
grep -nE '\b(vuln|fix)\w*_rc\s*=|^=+ *(vuln|fix)\b|^rc=' "$LOG" || echo "  none printed"

echo
echo "=== the first frames of the fault, for attribution ==="
grep -nE '^ +#[0-9]+ ' "$LOG" | head -6 || echo "  no backtrace"

echo
echo "=== the log's own conclusion ==="
grep -nE '^(RESULT|DECISION|SUMMARY|=+ *DIFFEREN)' "$LOG" || echo "  none"
