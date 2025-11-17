FROM ubuntu:20.04

LABEL maintainer="gpriamo"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -q update
RUN apt-get install -qq -y --no-install-recommends m4
RUN apt-get install -qq -y --no-install-recommends libtool
RUN apt-get install -qq -y --no-install-recommends autotools-dev
RUN apt-get install -qq -y --no-install-recommends automake
RUN apt-get install -qq -y --no-install-recommends wget
RUN apt-get install -qq -y --no-install-recommends lsb-release
RUN apt-get install -qq -y --no-install-recommends software-properties-common
RUN apt-get install -qq -y --no-install-recommends git
RUN apt-get install -qq -y --no-install-recommends make
RUN apt-get install -qq -y --no-install-recommends gawk
RUN apt-get install -qq -y --no-install-recommends bison
RUN apt-get install -qq -y --no-install-recommends libstdc++-9-dev
RUN apt-get install -qq -y --no-install-recommends htop
RUN apt-get install -qq -y --no-install-recommends zip
RUN apt-get install -qq -y --no-install-recommends unzip
RUN apt-get install -qq -y --no-install-recommends subversion
RUN apt-get install -qq -y --no-install-recommends build-essential
RUN apt-get install -qq -y --no-install-recommends python3-dev
RUN apt-get install -qq -y --no-install-recommends cmake
RUN apt-get install -qq -y --no-install-recommends flex
RUN apt-get install -qq -y --no-install-recommends libglib2.0-dev
RUN apt-get install -qq -y --no-install-recommends libpixman-1-dev
RUN apt-get install -qq -y --no-install-recommends python3-setuptools
RUN apt-get install -qq -y --no-install-recommends cargo
RUN apt-get install -qq -y --no-install-recommends libgtk-3-dev
RUN apt-get install -qq -y --no-install-recommends lcov
RUN apt-get install -qq -y --no-install-recommends nano
RUN apt-get install -qq -y --no-install-recommends less
RUN apt-get install -qq -y --no-install-recommends tar
RUN apt-get install -qq -y --no-install-recommends time
RUN apt-get install -qq -y --no-install-recommends linux-tools-common 
RUN apt-get install -qq -y --no-install-recommends linux-tools-generic 
#RUN apt-get install -qq -y --no-install-recommends linux-tools-`uname -r`
RUN apt-get install -qq -y --no-install-recommends gdb
RUN apt-get install -qq -y --no-install-recommends curl
RUN apt-get install -qq -y --no-install-recommends libc++-11-dev
RUN apt-get install -qq -y --no-install-recommends p7zip-full
RUN apt-get install -qq -y --no-install-recommends texinfo

RUN mkdir -p /home/afl
COPY . /home/afl

RUN wget https://github.com/llvm/llvm-project/releases/download/llvmorg-12.0.1/clang+llvm-12.0.1-x86_64-linux-gnu-ubuntu-16.04.tar.xz
RUN tar xf clang+llvm-12.0.1-x86_64-linux-gnu-ubuntu-16.04.tar.xz
RUN mv clang+llvm-12.0.1-x86_64-linux-gnu-ubuntu- /opt/clang+llvm-12.0.1-x86_64-linux-gnu-ubuntu/
ENV PATH="/opt/clang+llvm-12.0.1-x86_64-linux-gnu-ubuntu/bin/:${PATH}"

WORKDIR /home/afl

ENV AFL_NO_UI=1
ENV AFL_SKIP_CPUFREQ=1
ENV AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1

#48h
ENV RUNTIME=172800 

#6h
ENV FUZZING_WINDOW_ORIG=21600
ENV REMOVE_CULLTIME=1

ENV PLACEHOLDER="@@"

ENV CC=clang 
ENV CXX=clang++ 
ENV LLVM_CONFIG=llvm-config 
RUN make

#Rust
RUN mkdir -p /home/app/Rust
RUN cd /home/app/Rust && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN /bin/bash -c "source ~/.cargo/env"
RUN cargo --help
RUN rustc --version

RUN rustup toolchain install 1.78.0 && \
    rustup default 1.78.0

# AFLTriage
RUN mkdir -p /home/app/AFLTriage
RUN cd /home/app/AFLTriage && git clone https://github.com/quic/AFLTriage.git 
RUN cd /home/app/AFLTriage/AFLTriage && cargo run
ENV PATH="/home/app/AFLTriage/AFLTriage/target/debug/:${PATH}"

ENV LLVM_DIR="/opt/clang+llvm-12.0.1-x86_64-linux-gnu-ubuntu/bin/"
ENV AFL_PATH="/home/afl/"
