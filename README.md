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

- [`dataset/`](dataset/) — the merged function-level splits, 537,591 rows across the three
  corpora, with the re-derived labels, the fixed counterpart of every confirmed vulnerable
  function, and the provenance of each label. Start with
  [`dataset/README.md`](dataset/README.md).

- [`bigvul_corrected/`](bigvul_corrected/) — Big-Vul alone, in its own release format, with
  the `vul` column replaced by these labels and every other column and row left as the
  release had them. For reproducing Big-Vul-only experiments without changing their data
  loader. The 10 GB file itself is a release asset; the folder holds the full list of label
  changes and how to download and verify it.

More will be added to this repository.

## The collection in one table

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
