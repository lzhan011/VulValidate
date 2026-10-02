#!/usr/bin/env bash
# Pull and run every published Big-Vul reproduction, keeping each log.
#
# Keeps going past a failure: one case that cannot run must not stop the sweep, and the
# summary at the end is what tells you how many actually showed a difference.
set -u
cd "$(dirname "$0")"
mkdir -p runs
REPO=vulvalidate/bigvul-repro
TAGS=$(tail -n +2 images.csv | cut -d, -f1)
n=0; ran=0
for t in $TAGS; do
  n=$((n+1))
  printf '[%s] %s ... ' "$n" "$t"
  if docker run --rm --network none "$REPO:$t" > "runs/$t.log" 2>&1; then
    printf 'exit 0\n'
  else
    printf 'exit %s\n' "$?"
  fi
  ran=$((ran+1))
done
echo
echo "ran $ran of $n; logs are in runs/"
echo
echo "cases whose log reports a sanitizer firing:"
grep -lE '(ERROR|WARNING): (Address|Memory|Undefined|Thread|Leak)Sanitizer' runs/*.log \
  | wc -l
echo "cases whose log states its own conclusion:"
grep -lE '^(RESULT|DECISION|=+ *DIFFEREN)' runs/*.log | wc -l
echo
echo "An exit code of 0 means the script finished, not that a vulnerability reproduced."
echo "See ../README.md for the three things that decide a run."
