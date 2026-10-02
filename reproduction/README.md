# Reproducing the findings

Every vulnerable label in this repository that is marked `dynamic_confirmed` was arrived at
by running the code: building the function, reaching it with an attack input, and recording
what happened on both sides of the upstream fix. This folder lets you re-run that yourself.

Each reproduction is a Docker image. One command, no clone, no account:

```bash
docker run --rm --network none vulvalidate/bigvul-repro:177740
```

The image compiles the vulnerable and the fixed version of the function from the two stored
bodies, with the same driver and the same input, runs both, and prints each side's real
integer exit code together with the sanitizer output. The only variable between the two
runs is which function body was compiled in.

## What is here

| folder | corpus | state |
|---|---|---|
| [`bigvul/`](bigvul/) | Big-Vul | 51 reproductions published |
| [`primevul/`](primevul/) | PrimeVul | reserved, nothing published yet |
| [`diversevul/`](diversevul/) | DiverseVul | reserved, nothing published yet |

## `--network none` is a claim being tested, not a precaution

Each image carries everything its reproduction needs, including any upstream library that
had to be built with a sanitizer. Cutting the network must therefore change nothing. Keep
the flag and every run re-tests that; if a case ever needs the network, that is a defect in
the image rather than something you did wrong.

## Reading what a run prints

**An exit code of 0 means the script finished, not that a vulnerability reproduced.** The
images deliberately do not assert their own conclusion: one that exited 0 only when it
agreed with the stored answer would be a tautology rather than a reproduction. What the
recorded verdict was ships inside each image, so you can compare rather than take it:

```bash
docker run --rm --entrypoint cat vulvalidate/bigvul-repro:177740 \
  /repro/dynamic_evidence/EXPECTED.json
```

Three things decide a run, in this order.

**1. The vulnerable side faults and the fixed side does not.** A sanitizer report, or a
non-zero exit code for that side. Two traps here:

- **MemorySanitizer and ThreadSanitizer print `WARNING:`, not `ERROR:`.** A check that
  greps only for `ERROR:` cannot see the whole MSan route, and MSan is the only oracle that
  sees uninitialised memory at all &mdash; AddressSanitizer is structurally blind to it.
- **Matching exit codes alone is not enough.** In at least one published case both sides
  exit 1, and the fixed side's 1 is an overflow check correctly *rejecting* the input. Its
  log says so. What separates the two sides there is where the sanitizer fired.

**2. The negative control is identical on both sides.** Most reproductions run a
well-formed input as well as the attack input. If the well-formed one also separates the
two sides, the difference is not about the vulnerability.

**3. The fault is attributed to the right function.** Read frame #0 and the frames beneath
it. A fault inside a function *called from* the labelled one still counts, and those rows
carry `confirmation_scope=reachability` in the index. A fault in a *caller*, in an
unrelated sibling, or in the harness's own code does not.

23 of the 51 published cases have no crash at all by design: their oracle is a
printed value or a counted quantity, such as the number of uninitialised slots a sanitizer
reports. The `oracle` column of [`bigvul/images.csv`](bigvul/images.csv) names which one
each case uses, and the run log states its own conclusion.

## What a confirmation does and does not claim

A reproduction shows that **a** vulnerability was triggered in that function. It does not
verify the CWE or CVE the original corpus assigned; those fields are reproduced from
upstream unchanged, and a function can fault in a way other than the one it was filed
under.

Nothing here was labelled from reading the code. A label was only changed to
non-vulnerable after an attack was attempted and nothing triggered, which is weaker than
proving the function safe &mdash; which is why every changed label is listed individually in
the per-corpus folders rather than folded silently into the data.

## If a pull or a run goes wrong

- **a gdb-based case warns** `Error disabling address space randomization: Operation not
  permitted` &mdash; harmless; add `--cap-add=SYS_PTRACE` to silence it.
- **a case exits 90, 91 or 93** &mdash; those are a reproduction script's own codes for a
  missing dependency. It should not happen with a published image; if it does, the image is
  wrong and not your machine.
- **disk** &mdash; each image is about 267 MB to download and roughly 800 MB unpacked, but they
  all share one base layer, so the second one you pull costs almost nothing.
