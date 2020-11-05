FROM debian:10 AS builder

RUN apt-get update && apt-get install -y \
  python3 \
  python3-dev \
  python3-pip \
  python3-setuptools \
  yasm \
  wget \
  curl \
  autoconf2.13 \
  git \
  clang \
  pkg-config \
  zlib1g-dev

# Resolve the "Could not detect environment shell!" error when building SpiderMonkey.
# The environment variable "SHELL" is missing in Docker, so it needs to be added by yourself.
ENV SHELL=/bin/sh
# Add /root/.cargo/bin to PATH
ENV PATH=/root/.cargo/bin:$PATH

# Install Rust and Cargo
# Installing from APT will install the old version.
# Officially, they recommend using Rustup, so you should use it.
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
  && rustup update

# Required deps
RUN cargo install --force cbindgen

WORKDIR /workspace

# Shallow clone from the mirror at https://hg.mozilla.org/mozilla-central
RUN git clone --depth=1 https://github.com/mozilla/gecko-dev.git

# Build SpiderMonkey
RUN cd gecko-dev/js/src \
  && autoconf2.13 \
  && mkdir build_OPT.OBJ \
  && cd build_OPT.OBJ \
  && ../configure \
  && make

FROM debian:10-slim

# Copy binary
COPY --from=builder /workspace/gecko-dev/js/src/build_OPT.OBJ/dist/bin/js /usr/local/bin

ENTRYPOINT [ "js" ]
