# PrimeVul with corrected labels

PrimeVul's three release files with the `target` column replaced by VulValidate's labels.
Every other field is the release's own, every row is still here in the release's own order,
and the release's train/validation/test partition is untouched, so code that already reads
PrimeVul needs no change beyond the file path.

## Which PrimeVul release this is built on

**PrimeVul-v0.1**, the metadata-enhanced release of 2024-09-05: 224,533 functions, 6,004 of
them vulnerable.

That is fewer than the 6,968 vulnerable and 228,800 benign functions the PrimeVul paper
reports in its Table III, and the difference is the authors' own, not an artefact of this
work. v0.1 adds commit URLs, CVE descriptions, NVD links and file-level context, and its
release note says it keeps only the vulnerabilities whose metadata they could retrieve:

> In PrimeVul-v0.1, we only include vulnerabilities that we successfully retrieved their
> metadata. For the full set of samples that we originally used in the paper, please refer
> to the original release.

| | original release (2024-03-27) | v0.1, used here |
|---|---|---|
| vulnerable | 6,968 | 6,004 |
| benign | 228,800 | 218,529 |
| pairs | 5,480 | 4,704 |
| fields per record | 8 | 15 |

Both releases were counted file by file to confirm this: the original release reproduces the
paper's Table III in all six of its cells, split by split. Every one of v0.1's 6,004
vulnerable functions carries a CWE, which is what dropping the metadata-incomplete ones
looks like from the inside.

So a reader comparing these files against the paper will find 964 fewer vulnerable
functions before any relabelling, and that gap is PrimeVul's, not VulValidate's.

## Files

| file | rows | vulnerable (release → here) | compressed |
|---|---|---|---|
| `primevul_train_labels_only.jsonl.gz` | 175,797 | 4,862 → 4,926 | 64 MB |
| `primevul_valid_labels_only.jsonl.gz` | 23,948 | 593 → 622 | 9 MB |
| `primevul_test_labels_only.jsonl.gz` | 24,788 | 549 → 567 | 9 MB |

```bash
gunzip -k primevul_train_labels_only.jsonl.gz
sha256sum -c SHA256SUMS
```

`SHA256SUMS` holds the digests of the decompressed files.

## What changed from the release

285 of the 224,533 rows have a different `target`. `label_changes.csv` lists every one,
keyed on the release's `idx`, with what the release said, what this file says, and why.

| change | rows | what happened |
|---|---|---|
| `cross_corpus_conflict_resolved` | 198 | the release labelled the function non-vulnerable, but a function with the same normalised body in Big-Vul or DiverseVul had a vulnerability triggered in it, so the label became 1 |
| `label_noise_corrected` | 73 | the release labelled the function vulnerable; it was built, attacked with inputs aimed at the claimed weakness, and nothing triggered, so the label became 0 |
| `label_inherited_from_identical_body` | 14 | the release labelled the function vulnerable, but a function with the same normalised body in Big-Vul carries a non-vulnerable verdict here, and the label was taken from it |

For the 198 conflict rows, `label_changes.csv` names the corpus and id of the confirmed
function that outranked the release's label, so each flip can be traced to the specific
evidence behind it. The same holds for the 14 inherited rows.

The remaining 224,248 rows keep the label the release gave them. 380 of those were never
reached by a dynamic attempt at all, so their labels are the release's claim and carry no
evidence either way; `build_record.json` counts them as `unchanged_no_v6_verdict`, with a
per-split breakdown.

## What a label here means

A 1 means a vulnerability was observed while running the function: it was compiled,
reached with an attack input, and the resulting failure was attributed to it by source line
range rather than by function name. It does not mean the CWE or CVE the release assigned was
verified — those fields are reproduced from PrimeVul unchanged.

A 0 that came from `label_noise_corrected` means an attack was attempted and nothing
triggered within the effort spent. That is weaker than proving the function safe, which is
why those rows are listed individually rather than folded silently into the files.

## Related

The merged three-corpus collection is in [`../combined_dataset/`](../combined_dataset/), with one schema
across Big-Vul, DiverseVul and PrimeVul, a `label_source` field on every row, and the fixed
counterpart of every confirmed vulnerable function. This folder exists for reproducing
PrimeVul-only experiments in their original format.
