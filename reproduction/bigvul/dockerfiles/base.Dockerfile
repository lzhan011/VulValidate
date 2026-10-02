# Base image for VulValidate reproduction cases.
#
# Pinned to a digest, not a tag: a tag moves and would silently change the compiler
# under a reproduction that is supposed to be fixed.
FROM ubuntu:22.04@sha256:0e5e4a57c2499249aafc3b40fcd541e9a456aab7296681a3994d631587203f97

ENV DEBIAN_FRONTEND=noninteractive

# /tmp arrives as drwxrwxr-x on this builder, without the sticky bit or world write.
# apt drops to the `_apt` user to fetch indexes, that user cannot write /tmp, and the
# repository then reads as unsigned -- "Couldn't create temporary file /tmp/apt.conf".
# Setting the mode the way /tmp is normally set is the whole fix.
RUN chmod 1777 /tmp && apt-get update && apt-get install -y --no-install-recommends \
      gcc g++ clang-14 llvm-14 \
      gdb make binutils file xxd ca-certificates \
      python3 python3-dev perl \
      libc6-dev \
 && ln -sf /usr/bin/clang-14 /usr/bin/clang \
 && ln -sf /usr/bin/clang++-14 /usr/bin/clang++ \
 && rm -rf /var/lib/apt/lists/*

# A reproduction writes its logs next to itself, so the workdir must be writable.
WORKDIR /repro

# Sanitizers inside a container: no core dumps, and do not let a leak report
# turn a clean fix side into a failure.
ENV ASAN_OPTIONS=disable_coredump=1:detect_leaks=0:abort_on_error=0 \
    MSAN_OPTIONS=disable_coredump=1 \
    UBSAN_OPTIONS=disable_coredump=1:print_stacktrace=1
