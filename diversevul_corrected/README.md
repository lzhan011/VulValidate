# DiverseVul with corrected labels

The DiverseVul release file with the `target` field replaced by VulValidate's labels. Every
other field is the release's own and every row is still here in the release's own order, so
code that already reads DiverseVul needs no change beyond the file path.

## Files

The file is newline-delimited JSON despite its `.json` name, 703 MB uncompressed and 113 MB
gzipped. GitHub caps a file inside a repository at 100 MB, so it ships as two pieces, each a
valid gzip stream on its own:

| file | rows | compressed |
|---|---|---|
| `diversevul_20230702_labels_only.part1.json.gz` | 165,246 | 62 MB |
| `diversevul_20230702_labels_only.part2.json.gz` | 165,246 | 51 MB |

```bash
cat diversevul_20230702_labels_only.part1.json.gz \
    diversevul_20230702_labels_only.part2.json.gz \
  | gunzip > diversevul_20230702_labels_only.json
sha256sum -c SHA256SUMS
```

Concatenated gzip members decompress as one stream, so that reproduces the single 703 MB
file; its digest was checked against the original before release.

Reading the pieces separately works too:

```python
import gzip, json
rows = []
for p in ("part1", "part2"):
    with gzip.open(f"diversevul_20230702_labels_only.{p}.json.gz", "rt") as fh:
        rows += [json.loads(line) for line in fh]
```

## What changed from the release

2,148 of the 330,492 rows have a different `target`. `label_changes.csv` lists every one.
DiverseVul's release carries no row id, so rows are keyed on **line number in the release
file**, counting from 0 — which is also how the labels were joined on.

| change | rows | what happened |
|---|---|---|
| `label_noise_corrected` | 2,002 | the release labelled the function vulnerable; it was built, attacked with inputs aimed at the claimed weakness, and nothing triggered, so the label became 0 |
| `cross_corpus_conflict_resolved` | 146 | the release labelled the function non-vulnerable, but a function with the same normalised body in Big-Vul or PrimeVul had a vulnerability triggered in it, so the label became 1 |

Vulnerable rows go from 18,945 in the release to 17,089 here. For the 146 conflict rows,
`label_changes.csv` names the corpus and id of the confirmed function that outranked the
release's label.

The remaining 328,344 rows keep the label the release gave them. 6,383 of those were never
reached by a dynamic attempt at all, so their labels are the release's claim and carry no
evidence either way; `build_record.json` counts them as `unchanged_no_v6_verdict`.

## One thing to know about DiverseVul specifically

The DiverseVul release does not ship the fixed version of its functions, so a vulnerable
function here cannot be paired with its repaired counterpart from the release alone. Where
this collection has such a pair it came from matching the same function in another corpus.
Any analysis that compares a function against its own fix needs to account for that.

## What a label here means

A 1 means a vulnerability was observed while running the function: it was compiled, reached
with an attack input, and the resulting failure was attributed to it by source line range
rather than by function name. It does not mean the CWE the release assigned was verified —
that field is reproduced from DiverseVul unchanged.

A 0 that came from `label_noise_corrected` means an attack was attempted and nothing
triggered within the effort spent. That is weaker than proving the function safe, which is
why those 2,002 rows are listed individually.

## Related

The merged three-corpus collection is in [`../combined_dataset/`](../combined_dataset/), with one schema
across the three corpora and a `label_source` field on every row. This folder exists for
reproducing DiverseVul-only experiments in their original format.
