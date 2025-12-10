#!/bin/bash

# This script should be invoked with `source`` to make environment variables available to the shell instance in use

MAIN_DIR=$(pwd)

export DEBIAN_FRONTEND=noninteractive

# Update and install packages
sudo apt-get -q update
sudo apt-get install -qq -y --no-install-recommends \
    m4 libtool autotools-dev automake wget lsb-release \
    software-properties-common git make gawk bison libstdc++-9-dev \
    htop zip unzip subversion build-essential python3-dev cmake \
    flex libglib2.0-dev libpixman-1-dev python3-setuptools cargo \
    libgtk-3-dev lcov nano less tar time linux-tools-common \
    linux-tools-generic gdb curl libc++-11-dev p7zip-full texinfo

# Download and install LLVM/Clang 12.0.1
if [[ ! -d /opt/clang+llvm-12.0.1-x86_64-linux-gnu-ubuntu/bin/ ]]; then 
    cd /tmp
    wget https://github.com/llvm/llvm-project/releases/download/llvmorg-12.0.1/clang+llvm-12.0.1-x86_64-linux-gnu-ubuntu-16.04.tar.xz
    tar xf clang+llvm-12.0.1-x86_64-linux-gnu-ubuntu-16.04.tar.xz
    sudo mv clang+llvm-12.0.1-x86_64-linux-gnu-ubuntu- /opt/clang+llvm-12.0.1-x86_64-linux-gnu-ubuntu/
fi
export PATH="/opt/clang+llvm-12.0.1-x86_64-linux-gnu-ubuntu/bin/:${PATH}"

# Set AFL environment variables
export AFL_NO_UI=1
export AFL_SKIP_CPUFREQ=1
export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1

# Runtime path-aware fuzzing variables (48h and 6h in seconds)
export RUNTIME=172800
export FUZZING_WINDOW_ORIG=21600
export REMOVE_CULLTIME=1
export PLACEHOLDER="@@"

# Set compiler environment variables
export CC=clang
export CXX=clang++
export LLVM_CONFIG=llvm-config

# Build
cd $MAIN_DIR
make

# Install Rust
if ! command -v cargo >/dev/null 2>&1; then
    cd /tmp
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y
fi
export PATH="~/.cargo/bin:${PATH}"
source ~/.cargo/env

# Check if the install succeeded
cargo --help
rustc --version

# Install specific Rust toolchain
rustup toolchain install 1.78.0
rustup default 1.78.0

# Install AFLTriage
if ! command -v afltriage >/dev/null 2>&1; then
    mkdir -p ${HOME}/AFLTriage
    cd ${HOME}/AFLTriage
    git clone https://github.com/quic/AFLTriage.git
    cd AFLTriage
    cargo run
fi
export PATH="${HOME}/AFLTriage/AFLTriage/target/debug/:${PATH}"

# Set final environment variables
export LLVM_DIR="/opt/clang+llvm-12.0.1-x86_64-linux-gnu-ubuntu/bin/"
export AFL_PATH=$MAIN_DIR
export BIND_CPU=0

cd $MAIN_DIR

echo "Setup complete! All environment variables are now available in your shell."
