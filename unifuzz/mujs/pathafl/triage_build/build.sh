#!/bin/bash

export MAIN_DIR=$(pwd)
export COMMON_OPTS="-O0 -g -fno-omit-frame-pointer -fno-function-sections -fno-unique-section-names"

if [[ $1 == "-ns" ]]; then
  export CFLAGS="${COMMON_OPTS} -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION"
elif [[ $1 == "-ub" ]]; then
  export CFLAGS="${COMMON_OPTS} -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -fsanitize=address -fsanitize=array-bounds,bool,builtin,enum,float-divide-by-zero,function,integer-divide-by-zero,null,return,returns-nonnull-attribute,shift,signed-integer-overflow,unreachable,vla-bound,vptr"
else
  export CFLAGS="${COMMON_OPTS} -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -fsanitize=address"
  export MCFLAGS="${COMMON_OPTS} -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -fsanitize=address"
fi

export CXXFLAGS="-stdlib=libc++ ${CFLAGS}"
export LDFLAGS="-fsanitize=address -Wl,--allow-multiple-definition"
export LIB_FUZZING_ENGINE="${AFL_PATH}libAFLDriver.a"

export ASAN_OPTIONS=detect_leaks=0

get_git_revision() {
  GIT_REPO="$1"
  GIT_REVISION="$2"
  TO_DIR="$3"
  [ ! -e $TO_DIR ] && git clone $GIT_REPO $TO_DIR && (cd $TO_DIR && git checkout -f $GIT_REVISION)
}

set -x 

[ ! -e mujs-1.0.2.zip ] && wget https://github.com/unifuzz/unibench/raw/master/mujs-1.0.2.zip
[ ! -e mujs-1.0.2/ ] && unzip -q mujs-1.0.2.zip
[ ! -e SRC ] && mv mujs-1.0.2 SRC

export CC="${LLVM_DIR}/clang"
export CXX="${LLVM_DIR}/clang++"

cp Makefile SRC/Makefile

#build_lib
rm -rf BUILD
cp -rf SRC BUILD

cd BUILD 
build=debug make

cd ..

cp BUILD/build/debug/mujs target
