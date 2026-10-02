# bigvul:177737 / CVE-2015-8382 -- php ext/pcre php_pcre_match_impl() reads the ovector
# returned by pcre_exec() without it ever having been initialised.
#
# This case cannot use the sample's stored bodies alone.  The uninitialised bytes come out
# of a REAL pcre_exec(), and MemorySanitizer only sees them if libpcre ITSELF is
# instrumented -- an uninstrumented libpcre reports clean no matter what, which is the
# sensitivity control the reproduction runs.  So the upstream library is built here, from
# source, inside the image.
#
# Stage one builds it; stage two keeps only the installed library and headers, so the
# published image carries the dependency and needs no network to run.

FROM vulvalidate/repro-base:1 AS upstream
# PCRE 8.36. NVD on CVE-2015-8382 says "PCRE before 8.37", so 8.36 is an affected
# version. sha256 of the tarball used here is recorded in UPSTREAM.json beside it; no
# upstream-published sha256 was found to compare against, and the tarball's own
# configure reports PACKAGE_VERSION='8.36'.
COPY upstream/pcre-8.36.tar.gz /src/
WORKDIR /src
RUN tar xzf pcre-8.36.tar.gz && cd pcre-8.36 \
 && CC=clang CXX=clang++ \
    CFLAGS='-fsanitize=memory -O1 -g -fno-omit-frame-pointer' \
    CXXFLAGS='-fsanitize=memory -O1 -g -fno-omit-frame-pointer' ./configure \
      --disable-shared --enable-utf --enable-unicode-properties \
      --disable-cpp \
      --prefix=/pathb/O1_misc_work/pcre_177737/inst836 \
 && make -j"$(nproc)" >/dev/null && make install \
 && test -f /pathb/O1_misc_work/pcre_177737/inst836/lib/libpcre.a

FROM vulvalidate/repro-base:1
LABEL org.opencontainers.image.title="VulValidate reproduction bigvul:177737"
LABEL vulvalidate.sample="bigvul:177737"
LABEL vulvalidate.cve="CVE-2015-8382"
LABEL vulvalidate.project="php"
LABEL vulvalidate.upstream="pcre-8.36, built with -fsanitize=memory inside this image"
# The reproduction computes its own library path six levels above its folder, which
# resolves to / in this image, so the install prefix is where the script already looks.
# --disable-cpp above is not a shortcut: pcre's own C++ unit tests link with g++, which
# cannot read the DWARF that clang with MSan emits, and they are the only thing that
# fails. The reproduction links libpcre.a and the C headers, nothing from the C++ wrapper.
COPY --from=upstream /pathb/ /pathb/
# The reproduction's gdb arms compile `#include <pcre.h>` without passing -I, so on the
# build machine they picked the header up from a system libpcre. Pointing CPATH at the
# 8.36 headers installed above resolves it without editing the script, and without
# mixing a distro 8.39 header against the 8.36 library that is actually linked.
ENV CPATH=/pathb/O1_misc_work/pcre_177737/inst836/include

COPY sample/ /repro/
RUN find /repro -name '*.sh' -exec chmod +x {} +
WORKDIR /repro/dynamic_evidence
CMD ["bash", "/repro/dynamic_evidence/repro.sh"]
