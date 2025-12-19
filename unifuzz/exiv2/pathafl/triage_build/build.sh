#!/bin/bash

export MAIN_DIR=$(pwd)
export COMMON_OPTS="-O0 -g -fno-omit-frame-pointer -fno-function-sections -fno-unique-section-names"

if [[ $1 == "-ns" ]]; then
  export CFLAGS="${COMMON_OPTS} -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION"
elif [[ $1 == "-ub" ]]; then
  export CFLAGS="${COMMON_OPTS} -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -fsanitize=address -fsanitize=array-bounds,bool,builtin,enum,float-divide-by-zero,function,integer-divide-by-zero,null,return,returns-nonnull-attribute,shift,signed-integer-overflow,unreachable,vla-bound,vptr"
else
  export CFLAGS="${COMMON_OPTS} -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -fsanitize=address"
fi

export CXXFLAGS="-stdlib=libc++ ${CFLAGS}"
export LINKER_FLAGS="${AFL_PATH}afl-compiler-rt.o -Wl,--allow-multiple-definition"
export LIB_FUZZING_ENGINE="${AFL_PATH}libAFLDriver.a"

export ASAN_OPTIONS=detect_leaks=0

get_git_revision() {
  GIT_REPO="$1"
  GIT_REVISION="$2"
  TO_DIR="$3"
  [ ! -e $TO_DIR ] && git clone $GIT_REPO $TO_DIR && (cd $TO_DIR && git checkout -f $GIT_REVISION)
}

set -x

[ ! -e exiv2-0.26.zip ] && wget https://github.com/unifuzz/unibench/raw/master/exiv2-0.26.zip
[ ! -e exiv2-0.26/ ] && unzip -q exiv2-0.26.zip
[ ! -e SRC ] && mv exiv2-0.26/ SRC

export CC="${LLVM_DIR}/clang"
export CXX="${LLVM_DIR}/clang++"

while [ ! -e target ]; do
#build_lib
  rm -rf BUILD
  cp -rf SRC BUILD
  
  cd BUILD 
  mkdir build
  cd build
  cmake -DEXIV2_ENABLE_SHARED=OFF ..
  make -j $(nproc)
  cd $MAIN_DIR
  
  cp BUILD/build/bin/exiv2 target
done