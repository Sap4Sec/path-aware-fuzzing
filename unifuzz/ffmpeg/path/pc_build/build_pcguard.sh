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

[ ! -e ffmpeg-4.0.1.tar.gz ] && wget https://github.com/unifuzz/unibench/raw/master/ffmpeg-4.0.1.tar.gz
[ ! -e ffmpeg-4.0.1/ ] && tar zxf ffmpeg-4.0.1.tar.gz
[ ! -e SRC/ ] && mv ffmpeg-4.0.1 SRC

#build_lib
rm -rf BUILD
cp -rf SRC BUILD

export CC="${AFL_PATH}/afl-clang-fast"
export CXX="${AFL_PATH}/afl-clang-fast++"

cd BUILD 
./configure --disable-shared --cc="$CC" --cxx="$CXX" --ld="$CXX $CXXFLAGS -std=c++11 $LDFLAGS" --pkg-config-flags="--static" --optflags=-O1
export PATH_DEBUG=1
make -j $(nproc)

cd ..

cp BUILD/ffmpeg_g target.afl

# CMPLOG
if [[ $2 == "-nc" ]]; then
    echo "NOT BUILDING COMPLOG"
else
  export AFL_LLVM_CMPLOG=1

  rm -rf BUILD_C
  cp -rf SRC BUILD_C
  cd BUILD_C 
  ./configure --disable-shared --cc="$CC" --cxx="$CXX" --ld="$CXX $CXXFLAGS -std=c++11 $LDFLAGS" --pkg-config-flags="--static" --optflags=-O1
  make -j $(nproc)
  
  cd ..

  cp BUILD_C/ffmpeg_g target.cmplog

  unset AFL_LLVM_CMPLOG
fi