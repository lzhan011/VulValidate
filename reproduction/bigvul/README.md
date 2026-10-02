# Big-Vul reproductions

51 findings from Big-Vul, each as a Docker image under one repository with one tag
per sample. The tag is the sample's Big-Vul index, so
`vulvalidate/bigvul-repro:177740` is Big-Vul sample 177740, the row with
`idx = 177740` in this repository's corpus files.

```bash
docker pull vulvalidate/bigvul-repro:177740
docker run --rm --network none vulvalidate/bigvul-repro:177740
```

[`images.csv`](images.csv) is the index: one row per published tag, with the CVE, the
project, the labelled function and file, the oracle, what each side of the fix does, and
whether the image had to build an upstream library itself.

| | |
|---|---|
| published reproductions | 51 |
| decided by a sanitizer | 28 |
| decided by a printed value or a count | 23 |
| images that build an upstream library inside themselves | 1 |
| distinct CVEs | 46 |
| projects | 21 |

Projects covered: NetworkManager, ghostscript, gnupg, gstreamer, haproxy, harfbuzz, libx11, libxfont, musl, openssl, php, polkit, poppler, postgresql, qemu, samba, savannah, shibboleth and more.

## Run them all

```bash
./run_all.sh            # pulls and runs every tag in images.csv, logs into runs/
./check.sh 177740        # run one and print the lines that decide it
```

`run_all.sh` keeps going past a failure and writes a summary at the end, so one bad case
does not stop the sweep.

## Where each image comes from

[`dockerfiles/`](dockerfiles/) holds the Dockerfile behind every published image, plus
`base.Dockerfile` for the shared base. Most are one stage: the build context is the
sample's own directory &mdash; the two stored function bodies, the driver, the attack input,
the negative control and `repro.sh` &mdash; and nothing else.

1 of them are two stages, because their oracle needs an upstream library compiled with a
sanitizer. `bigvul-177737.Dockerfile` is the clearest example: the uninitialised bytes it
detects come out of a real `pcre_exec()`, and MemorySanitizer only sees them if libpcre
*itself* is instrumented, so the first stage builds PCRE 8.36 with `-fsanitize=memory` and
the second keeps only the installed library. The version and the full configure line are in
the Dockerfile, and the published image still runs with no network.

## This is a subset

Of 10,904 Big-Vul samples, 6,749 carry a reproduction script. 51 are published here.
The rest fall into three groups:

- **their reproduction needs an upstream build** that was made separately when the finding
  was first established &mdash; a sanitizer-instrumented library, a kernel tree, a built
  binary. Those need one recipe per upstream, and 177737 shows the shape a recipe takes.
- **their recorded verdict is not a confirmation** &mdash; undecided, or a label that was
  corrected to non-vulnerable. There is nothing to reproduce.
- **the image was built but showed no difference between the two sides.** Those are *not*
  published: an image that runs to completion without reproducing anything invites being
  read as evidence that the finding is not real, when all it shows is that this packaging
  did not carry what the reproduction needed.

More are added as they are built and verified; `images.csv` is regenerated from the live
tag list, so it never lists a tag the registry does not have.
