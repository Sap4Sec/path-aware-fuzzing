#!/bin/bash

if [ $(whoami) == gpriamo ]; then #local tests
    export LLVM_DIR="/opt/clang+llvm-12.0.1-x86_64-linux-gnu-ubuntu/bin/"
    export AFL_PATH="/home/gpriamo/PhD/Projects/FuzzingCollab/BL-classic-mode/"
else
    export LLVM_DIR=${DHOME}/tools/llvm12/bin/
    export PATH=$LLVM_DIR:$PATH
    export AFL_PATH="/home/afl/"
fi

export MAIN_DIR=$(pwd)
export COMMON_OPTS="-O1 -g -fno-omit-frame-pointer -fno-function-sections -fno-unique-section-names"

if [[ $1 == "-ns" ]]; then
  export CFLAGS="${COMMON_OPTS} -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION"
elif [[ $1 == "-ub" ]]; then
  export CFLAGS="${COMMON_OPTS} -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -fsanitize=address -fsanitize=array-bounds,bool,builtin,enum,float-divide-by-zero,function,integer-divide-by-zero,null,return,returns-nonnull-attribute,shift,signed-integer-overflow,unreachable,vla-bound,vptr"
else
  export CFLAGS="${COMMON_OPTS} -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -fsanitize=address"
fi

export CXXFLAGS="-stdlib=libc++ ${CFLAGS}"
export LDFLAGS="${AFL_PATH}afl-compiler-rt.o -Wl,--allow-multiple-definition"
export LIB_FUZZING_ENGINE="${AFL_PATH}libAFLDriver.a"

export ASAN_OPTIONS=detect_leaks=0

get_git_revision() {
  GIT_REPO="$1"
  GIT_REVISION="$2"
  TO_DIR="$3"
  [ ! -e $TO_DIR ] && git clone $GIT_REPO $TO_DIR && (cd $TO_DIR && git checkout -f $GIT_REVISION)
}

set -x 

#get_git_revision https://gitlab.gnome.org/GNOME/libxml2.git v2.9.2 SRC

if [[ $(whoami) = root && ! -e cmake-3.29.2-linux-x86_64.sh ]]; then
  wget https://github.com/Kitware/CMake/releases/download/v3.29.2/cmake-3.29.2-linux-x86_64.sh && \
      chmod +x cmake-3.29.2-linux-x86_64.sh && \
      ./cmake-3.29.2-linux-x86_64.sh --skip-license --prefix="/usr/local"
fi

git clone https://github.com/axiomatic-systems/Bento4.git SRC

export CC="${AFL_PATH}/afl-clang-fast"
export CXX="${AFL_PATH}/afl-clang-fast++"

i=0

while [ ! -e target.afl ]; do
  echo "Build attempt #${i}"
  sleep $i
  #build_lib
  rm -rf BUILD
  cp -rf SRC BUILD
  
  cd BUILD 
  mkdir build
  cd build 
  cmake ..
  export PATH_DEBUG=1
  make -j $(nproc)
  
  cd $MAIN_DIR
  
  cp BUILD/build/mp42aac target.afl

  i=$((i + 1))
done

i=0

# CMPLOG
if [[ $2 == "-nc" ]]; then
    echo "NOT BUILDING COMPLOG"
else
  export AFL_LLVM_CMPLOG=1
  while [ ! -e target.cmplog ]; do
    echo "[CMPLOG] Build attempt #${i}"
    sleep $i

    rm -rf BUILD_C
    cp -rf SRC BUILD_C
    cd BUILD_C 
    mkdir build
    cd build 
    cmake ..
    make -j $(nproc)

    cd $MAIN_DIR

    cp BUILD_C/build/mp42aac target.cmplog
  
    i=$((i + 1))
  done
  unset AFL_LLVM_CMPLOG
fi