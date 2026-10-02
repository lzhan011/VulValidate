# PrimeVul reproductions

**Reserved. Nothing is published here yet.**

The PrimeVul side of this repository currently ships corrected labels
([`../../primevul_corrected/`](../../primevul_corrected/)) but not runnable reproductions.

When they arrive, this folder will have the same shape as
[`../bigvul/`](../bigvul/):

```
primevul/
  README.md          counts, projects, what the subset covers and what it leaves out
  images.csv         one row per published tag: CVE, project, labelled function,
                     oracle, what each side of the fix does
  run_all.sh         pull and run every tag, keep the logs
  check.sh           run one and point at the lines that decide it
  dockerfiles/       the Dockerfile behind each image, plus the shared base
```

and the images will be at `vulvalidate/primevul-repro:<tag>`, where the tag is the sample's
index in the PrimeVul release.

Reading a run is the same in every corpus, so [`../README.md`](../README.md) covers it:
an exit code of 0 does not mean a vulnerability reproduced, MemorySanitizer prints
`WARNING:` rather than `ERROR:`, the negative control has to stay identical on both sides,
and the fault has to be attributed to the labelled function or to something it calls.
