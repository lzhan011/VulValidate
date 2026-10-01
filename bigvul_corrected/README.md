# Big-Vul with corrected labels

`MSR_data_cleaned.csv` from the Big-Vul release, with the `vul` column replaced by
VulValidate's labels. Every other column is the release's own, unchanged, and every one of
the release's 188,636 rows is still here — nothing was dropped and nothing was deduplicated.
Code that already reads Big-Vul in this format needs no change beyond the file path.

## Getting it

The file is 10.05 GB, which is far past GitHub's 100 MB limit for a file inside a
repository, so it is attached to a release instead:

```bash
curl -L -o MSR_data_cleaned_labels_only.csv.gz \
  https://github.com/lzhan011/VulValidate/releases/download/bigvul-corrected/MSR_data_cleaned_labels_only.csv.gz
gunzip MSR_data_cleaned_labels_only.csv.gz
sha256sum -c MSR_data_cleaned_labels_only.csv.sha256
```

The checksum file in this folder is the digest of the decompressed CSV, so the last command
proves the download and the decompression were both clean.

## What changed from the release

2,156 of the 188,636 rows have a different `vul` value. `label_changes.csv` lists every
one of them, with what the release said, what this file says, and why.

| change | rows | what happened |
|---|---|---|
| `label_noise_corrected` | 1,130 | the release labelled the function vulnerable; it was built, attacked with inputs aimed at the claimed weakness, and nothing triggered, so the label became 0 |
| `cross_corpus_conflict_resolved` | 1,024 | the release labelled the function non-vulnerable, but a function with the same normalised body in DiverseVul or PrimeVul had a vulnerability triggered in it, so the label became 1 |
| `identical_to_a_fixed_function` | 2 | the release labelled the function vulnerable, but its normalised body is identical to the post-fix side of another Big-Vul row, so the label became 0 |

The two rows of the last kind are 179657 and 179666, whose bodies equal the repaired
versions of 179219 and 179214. `build_record.json` counts them inside its
`relabelled: 1132`, which is why that number is two larger than the label-noise count here:
they were corrected on a different ground and are listed separately.

The remaining 186,480 rows keep the label the release gave them. 5,356 of those were never
reached by a dynamic attempt at all, so their labels are the release's claim and carry no
evidence either way; `build_record.json` counts them as `unchanged_no_v6_verdict`.

For the conflict rows, `label_changes.csv` also names the corpus and id of the function
that outranked the release's label and the shared body hash, so each flip can be traced to
the specific confirmed twin behind it.

## What a label here means

A 1 means a vulnerability was observed while running the function: it was compiled,
reached with an attack input, and the resulting failure was attributed to it by source line
range rather than by function name. It does not mean the CWE or CVE the release assigned was
verified — those columns are reproduced from Big-Vul unchanged, and a function can trigger a
different weakness than the one it was filed under.

A 0 that came from `label_noise_corrected` means an attack was attempted and nothing
triggered within the effort spent. That is weaker than proving the function safe, and it is
the reason these rows are listed individually rather than folded silently into the file.

## Other things in this folder

- `label_changes.csv` — all 2,156 changed rows
- `build_record.json` — the counts the build produced, including how each decision was sourced
- `MSR_data_cleaned_labels_only.csv.sha256` — digest of the decompressed CSV

## Related

The merged three-corpus collection is in [`../dataset/`](../dataset/). It is the better
starting point for new work: one schema across Big-Vul, DiverseVul and PrimeVul, a
`label_source` field on every row, and the fixed counterpart of every confirmed vulnerable
function. This folder exists for reproducing Big-Vul-only experiments in their original
format.
