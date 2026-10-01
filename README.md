# VulValidate

Labels for vulnerability-detection benchmarks, re-derived by running the code instead of
trusting the release.

Big-Vul, DiverseVul and PrimeVul label a function vulnerable because a commit that fixed
a CVE touched it. That is a claim about a commit, not about the function. VulValidate
re-examines those claims: it builds the function, attacks it, and records what happened.
A function is called vulnerable here only when a vulnerability was actually triggered in
it; a label is changed to non-vulnerable only when an attack was attempted and nothing
triggered, never on a reading of the code.

## What is here

- [`combined_dataset/`](combined_dataset/) — all three corpora merged into one, 537,591
  rows, with the corrected labels, the fixed counterpart of every confirmed vulnerable
  function, and the provenance of each label. Start with
  [`combined_dataset/README.md`](combined_dataset/README.md).

- [`bigvul_corrected/`](bigvul_corrected/) — Big-Vul alone, in its own release format, with
  the `vul` column replaced by these labels and every other column and row left as the
  release had them. For reproducing Big-Vul-only experiments without changing their data
  loader. The 10 GB file itself is a release asset; the folder holds the full list of label
  changes and how to download and verify it.

- [`primevul_corrected/`](primevul_corrected/) — PrimeVul alone, its three release files with
  `target` replaced by these labels, partition and field layout untouched.
- [`diversevul_corrected/`](diversevul_corrected/) — DiverseVul alone, same arrangement.

Each per-corpus folder lists every label it changed from that corpus's release, with the
reason for each one.

More will be added to this repository.

## Each corpus on its own

| | rows | vulnerable (release → here) | labels changed |
|---|---|---|---|
| Big-Vul | 188,636 | 10,900 → 10,792 | 2,156 |
| DiverseVul | 330,492 | 18,945 → 17,089 | 2,148 |
| PrimeVul | 224,533 | 6,004 → 6,115 | 285 |

The PrimeVul row counts **PrimeVul-v0.1**, which holds 6,004 vulnerable functions where the
PrimeVul paper reports 6,968; v0.1 keeps only the vulnerabilities whose metadata its authors
could retrieve, and [`primevul_corrected/`](primevul_corrected/) sets the two releases side
by side.

PrimeVul gains vulnerable functions where the other two lose them: most of its changes are
functions it labelled non-vulnerable that a confirmed twin in another corpus outranked.

## The merged collection in one table

| | rows | vulnerable | pairs |
|---|---|---|---|
| train | 430,023 | 12,682 | 11,744 |
| validation | 53,772 | 1,599 | 1,486 |
| test | 53,796 | 1,609 | 1,482 |

15,890 functions carry a triggered vulnerability, 3,180 had a vulnerable label removed
after an attack found nothing, and 14,712 are the post-fix counterparts of confirmed
functions. The remaining 503,809 keep the non-vulnerable label their original release
gave them.

## Why the labels matter for measurement

A detector's precision is measured against the labels, so label noise moves the score
without anything about the detector changing. On Big-Vul, scoring one unchanged LineVul
checkpoint against the corrected labels instead of the original ones takes its F1 from
0.8551 to 0.5940 — its predictions are identical, and its false positives rise from 87 to
501 because the reference changed. Its AUROC moves from 0.9646 to 0.9599. The ranking the
model produces barely moves; what moves is where a fixed decision threshold sits in the
new label distribution.

## Licence and provenance

The function bodies, commit ids and CVE references come from the Big-Vul, DiverseVul and
PrimeVul releases and from the upstream open-source projects they were collected from;
their terms apply to that content. What this repository adds is the labels, the pairings
and the provenance records.

Please cite the three source corpora alongside this work.
