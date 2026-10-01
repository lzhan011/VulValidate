# Combined dataset

Big-Vul, DiverseVul and PrimeVul with their corrected labels, merged into one
function-level collection under a single schema, with every vulnerable label re-derived
from a dynamic attack rather than inherited from the original release.

Each corpus is also published on its own, in its own release format, under
[`../bigvul_corrected/`](../bigvul_corrected/),
[`../primevul_corrected/`](../primevul_corrected/) and
[`../diversevul_corrected/`](../diversevul_corrected/). Those keep each release's fields and
row order for code that already reads them; this folder is the merged version.

Every file is newline-delimited JSON, gzipped. The train split is in two pieces because
GitHub refuses any single file over 100 MB; each piece is a valid `.jsonl.gz` on its own.

## Files

| file | rows | vulnerable | compressed |
|---|---|---|---|
| `train.part1.jsonl.gz` + `train.part2.jsonl.gz` | 430,023 | 12,682 | 54 + 74 MB |
| `valid.jsonl.gz` | 53,772 | 1,599 | 19 MB |
| `test.jsonl.gz` | 53,796 | 1,609 | 18 MB |
| `train_paired.jsonl.gz` | 23,488 | 11,744 | 15 MB |
| `valid_paired.jsonl.gz` | 2,972 | 1,486 | 2 MB |
| `test_paired.jsonl.gz` | 2,964 | 1,482 | 2 MB |

`MANIFEST.json` carries, for each file, the line count and the sha256 of its
**decompressed** stream, plus the sha256 of the original uncompressed file. The two train
pieces were checked to concatenate back to the original digest before release.

## Reading them

```python
import gzip, json

def read(path):
    with gzip.open(path, "rt") as fh:
        for line in fh:
            yield json.loads(line)

train = list(read("combined_dataset/train.part1.jsonl.gz")) + \
        list(read("combined_dataset/train.part2.jsonl.gz"))
```

To get the original single file back:

```bash
cat combined_dataset/train.part1.jsonl.gz combined_dataset/train.part2.jsonl.gz | gunzip > train.jsonl
```

That works because concatenated gzip members decompress as one stream.

## Fields

| field | what it holds |
|---|---|
| `id` | `<corpus>:<index in that corpus's release>`, unique across the collection |
| `idx` | row number inside this collection |
| `dataset` | `bigvul`, `diversevul` or `primevul` |
| `source_index` | the index this function had in its own corpus |
| `target` | 1 vulnerable, 0 not |
| `func` | the function body |
| `label_source` | how this row's label was arrived at — see below |
| `pair_of`, `pair_row`, `pair_int_id`, `role` | links a vulnerable function to its fixed counterpart |
| `project`, `commit_id`, `code_link` | provenance in the upstream project |
| `cwe`, `cve`, `cve_ids` | the advisory the label came from, where there is one |
| `lang` | `C` or `C++` |
| `source_target` | the label the original release carried, kept for comparison |
| `metadata_source`, `metadata_scope` | which record the metadata was read from |

### `label_source`

| value | rows | meaning |
|---|---|---|
| `original_non_vulnerable` | 503,809 | the original release labelled it non-vulnerable and nothing changed that |
| `dynamic_confirmed` | 15,890 | a vulnerability was triggered in this function by running it under a sanitizer or an equivalent oracle |
| `fixed_function_of_confirmed` | 14,712 | the post-fix counterpart of a confirmed function, labelled non-vulnerable |
| `dynamic_label_noise_corrected` | 3,180 | the original release labelled it vulnerable, a dynamic attack did not trigger anything, and the label was changed to non-vulnerable |

`dynamic_confirmed` is the one claim that carries evidence: the function was compiled,
reached with an attack input, and the failure was attributed to it. A label was never
changed to non-vulnerable on a reading of the code alone.

The rules behind those four values — the four permitted outcomes, the two-sided
differential, attribution by line range rather than by function name, and the gates a
label-noise decision has to pass — are published as an installable Agent Skill:
[vuln-label-dynamic-confirmation](https://github.com/lzhan011/vuln-label-dynamic-confirmation-skill).

## Pairs

The `*_paired.jsonl.gz` files hold only confirmed vulnerable functions and their fixed
counterparts, two rows per pair, the vulnerable one first. Every row in them also appears
in the matching `train`/`valid`/`test` file, so the pairs are a view of the splits and not
extra data. They exist for metrics that need both sides of a fix — a detector that flags
the vulnerable function and clears the fixed one has done something a single-function
score cannot show.

Pair counts: 11,744 in train, 1,486 in validation, 1,482 in test, 14,712 in total. That
is fewer than the 15,890 confirmed vulnerable functions: 1,178 of them have no fixed
counterpart available, so they appear in the splits but in none of the pair files.

## Composition

| split | Big-Vul | DiverseVul | PrimeVul |
|---|---|---|---|
| train | 149,420 | 164,067 | 116,536 |
| validation | 18,582 | 20,683 | 14,507 |
| test | 18,632 | 20,465 | 14,699 |

The PrimeVul side is built on **PrimeVul-v0.1** (224,533 functions, 6,004 vulnerable), not
the original release the PrimeVul paper reports (235,768 / 6,968); v0.1 keeps only the
vulnerabilities whose metadata its authors could retrieve. See
[`../primevul_corrected/README.md`](../primevul_corrected/README.md) for the comparison.

Splitting is by function, and a vulnerable function and its fixed counterpart always land
in the same split, so a model cannot see one side in training and be tested on the other.

## What this does and does not establish

A row marked `dynamic_confirmed` means a vulnerability was observed, not that the
function's original CWE or CVE assignment was confirmed; those are reproduced from
upstream unchanged. A row marked `dynamic_label_noise_corrected` means an attack did not
trigger anything within the effort spent, which is weaker than proving the function safe.
Functions that could not be built or reached are labelled from their original release and
are not marked as either.
