#!/bin/bash

if [ $(ip a | grep -c 192.168.60.200) -eq 1 ]; then
    PREFIX=${HOME}
else
    PREFIX="/mnt/system/giacomo/fuzzing/"
fi
#PREFIX="${SRC_HOME}/giacomo/"

SRC_HOME=${HOME}

echo "Binding on ${SRC_HOME}"

#BIND_CPU=$(cat cpu)
BIND_CPU=$(echo $(basename $0 .sh) | cut -d "." -f 2)
#inc=$(($(nproc)/2))
#BIND_CPU_SIBL=$(($BIND_CPU+$inc))

#echo "BINDING ON 2 CPUS: ${BIND_CPU}, ${BIND_CPU_SIBL}"

if [ $1 = "-r" ]; then
    docker run --cpuset-cpus="${BIND_CPU}" -v ${SRC_HOME}/tools/llvm12/:${SRC_HOME}/tools/llvm12/ -v ${PREFIX}/BL-classic-mode/:/home/afl/ \
        -v ${PREFIX}/BL-classic-mode/unifuzz/flvmeta/path/afl_out_${BIND_CPU}/:/home/app/benches/bench/afl_out_${BIND_CPU} \
        #-v ${SRC_HOME}/tools/go/:${SRC_HOME}/tools/go/ -v ${SRC_HOME}/go/:${SRC_HOME}/go/ \
        #-v /usr/lib/x86_64-linux-gnu/libpython3.5m.so.1.0:/usr/lib/x86_64-linux-gnu/libpython3.5m.so.1.0 -v ${SRC_HOME}/giacomo/afl-cov/:/usr/local/bin/ \
        flvmeta-path:latest
else
    docker run --cpuset-cpus="${BIND_CPU}" -v ${SRC_HOME}/tools/llvm12/:${SRC_HOME}/tools/llvm12/ -v ${PREFIX}/BL-classic-mode/:/home/afl/ \
        -v ${PREFIX}/BL-classic-mode/unifuzz/flvmeta/path/afl_out_${BIND_CPU}/:/home/app/benches/bench/afl_out_${BIND_CPU} \
        -it flvmeta-path:latest /bin/bash
fi