#!/bin/bash

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

if [ $(whoami) = root && ! -e cmake-3.16.4-Linux-x86_64.sh ]; then
  wget https://github.com/Kitware/CMake/releases/download/v3.16.4/cmake-3.16.4-Linux-x86_64.sh && \
      chmod +x cmake-3.16.4-Linux-x86_64.sh && \
      ./cmake-3.16.4-Linux-x86_64.sh --skip-license --prefix="/usr/local"
fi

[ ! -e exiv2-0.26.zip ] && wget https://github.com/unifuzz/unibench/raw/master/exiv2-0.26.zip
[ ! -e exiv2-0.26/ ] && unzip -q exiv2-0.26.zip
[ ! -e SRC ] && mv exiv2-0.26/ SRC

export CC="${AFL_PATH}/afl-clang-fast"
export CXX="${AFL_PATH}/afl-clang-fast++"

rm -rf BUILD
cp -rf SRC BUILD
cd BUILD 
mkdir build
cd build
cmake -DEXIV2_ENABLE_SHARED=OFF ..
make -j $(nproc)
cd $MAIN_DIR
cp BUILD/build/bin/exiv2 target.afl

# CMPLOG
if [[ $2 == "-nc" ]]; then
    echo "NOT BUILDING COMPLOG"
else
  export AFL_LLVM_CMPLOG=1

  rm -rf BUILD_C
  cp -rf SRC BUILD_C
  cd BUILD_C 
  mkdir build
  cd build
  cmake -DEXIV2_ENABLE_SHARED=OFF ..
  make -j $(nproc)
  cd $MAIN_DIR
  cp BUILD_C/build/bin/exiv2 target.cmplog

  unset AFL_LLVM_CMPLOG
fi