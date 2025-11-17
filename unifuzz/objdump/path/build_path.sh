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

[ ! -e binutils-2.28.tar.gz ] && wget https://github.com/unifuzz/unibench/raw/master/binutils-2.28.tar.gz
[ ! -e binutils-2.28/ ] && tar zxf binutils-2.28.tar.gz
[ ! -e SRC ] && mv binutils-2.28 SRC

#build_lib
rm -rf BUILD
cp -rf SRC BUILD

export AFL_PATH_PROFILING="1"
export AFL_LLVM_INSTRUMENT="classic"

export CC="${AFL_PATH}/afl-clang-fast"
export CXX="${AFL_PATH}/afl-clang-fast++"

cd BUILD 
./configure --disable-shared
export PATH_DEBUG=1
make -j 

cd ..

cp BUILD/binutils/objdump target.afl

# CMPLOG
if [[ $2 == "-nc" ]]; then
    echo "NOT BUILDING COMPLOG"
else
  export AFL_LLVM_CMPLOG=1

  rm -rf BUILD_C
  cp -rf SRC BUILD_C
  cd BUILD_C 
  ./configure --disable-shared
  make -j $(nproc) 
  
  cd ..

  cp BUILD_C/binutils/objdump target.cmplog

  unset AFL_LLVM_CMPLOG
fi