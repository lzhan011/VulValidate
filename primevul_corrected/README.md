# PrimeVul with corrected labels

PrimeVul's three release files with the `target` column replaced by VulValidate's labels.
Every other field is the release's own, every row is still here in the release's own order,
and the release's train/validation/test partition is untouched, so code that already reads
PrimeVul needs no change beyond the file path.

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

The merged three-corpus collection is in [`../dataset/`](../dataset/), with one schema
across Big-Vul, DiverseVul and PrimeVul, a `label_source` field on every row, and the fixed
counterpart of every confirmed vulnerable function. This folder exists for reproducing
PrimeVul-only experiments in their original format.
