FROM ubuntu:jammy AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y autoconf automake build-essential cmake git \
    libass-dev libbz2-dev libfontconfig-dev libfreetype-dev libfribidi-dev libharfbuzz-dev \
    libjansson-dev liblzma-dev libmp3lame-dev libnuma-dev libogg-dev libopus-dev libsamplerate0-dev \
    libssl-dev libspeex-dev libtheora-dev libtool libtool-bin libturbojpeg0-dev libvorbis-dev \
    libx264-dev libxml2-dev libvpx-dev m4 make meson nasm ninja-build patch pkg-config tar zlib1g-dev \
    libva-dev libdrm-dev appstream desktop-file-utils gettext gstreamer1.0-libav gstreamer1.0-plugins-good \
    libgstreamer-plugins-base1.0-dev libgtk-4-dev curl rustc cargo

# Install Rust dependencies
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN cargo install cargo-c
RUN rustup target add x86_64-unknown-linux-gnu
RUN rustc --version && cargo --version

RUN mkdir -p /build/.cargo
RUN mkdir -p /build/.rustup
RUN cp -r /root/.rustup /build/
RUN cp -r /root/.cargo /build/

# Make sure Rust files were copied correctly
RUN ls -la /build/.cargo && ls -la /build/.rustup

# Clone and build HandBrake
ARG TAG=1.8.2
RUN mkdir -p /tmp/bld && \
    cd /tmp/bld && \
    git clone --depth 1 --branch ${TAG} https://github.com/HandBrake/HandBrake.git

# Verify the cloned repository
RUN ls -la /tmp/bld/HandBrake

WORKDIR /tmp/bld/HandBrake
RUN ./configure --launch-jobs=$(nproc) --launch --enable-qsv
RUN make --directory=build install

# Verify built assetes
RUN ls -la /tmp/bld/HandBrake/build/gtk/src/ghb && ls -la /tmp/bld/HandBrake/build/HandBrakeCLI

# Export built assetes
RUN mkdir -p /build/gtk
RUN cp -r /tmp/bld/HandBrake/build/gtk /build/
RUN cp /tmp/bld/HandBrake/build/HandBrakeCLI /build

# Verify exported assetes were copied correctly
RUN ls -la /build/gtk && \
    ls -la /build/gtk/src && \
    ls -la /build/gtk/src/ghb && \
    ls -la /build/HandBrakeCLI

WORKDIR /

RUN mkdir -p /build/gtk
RUN cp -r /tmp/bld/HandBrake/build/gtk /build/
