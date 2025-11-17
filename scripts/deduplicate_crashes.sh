#!/bin/bash

# Deduplicate the crashes detected during a fuzzing campaign using the AFLTriage tool,
# after building a clean version of the subject (i.e., without the fuzzer's instrumentation).
# In case of a normal fuzzing run (path, pcguard, opp fuzzers), 
# the deduplicated crashes will be saved under the afl_out_*/u-crashes5 path.
# For a culling run (cull fuzzer), the deduplicated crashes for each fuzzing round will be 
# saved under the afl_out_*/u-crashes5/u-* path, and merged in under the afl_out_*/u-crashes5/uniques path.

echo $(pwd)

set -x

scripts_dir=$(dirname -- "$( readlink -f -- "$0"; )")

out_dir=$(find . -name afl_out* | xargs echo)

cd triage_build && bash ./build.sh -ub && cd .. # Build the clean version of the program

cull_dir=$(find . -maxdepth 1 -type d -name "f[1-9]*_*")

if [[ $PLACEHOLDER == "" ]]; then
    PH=""
    STDIN="--stdin"
else
    PH=$PLACEHOLDER
fi

if [[ $cull_dir == "" ]]; then
    cp -r ./${out_dir}/default/crashes/ ./${out_dir}/default/backup-crashes/
    afltriage -i ./${out_dir}/default/crashes/ -o ./${out_dir}/u-crashes5 $STDIN --bucket-strategy first_5_frames ./triage_build/target $PH
else
    mkdir ${out_dir}/u-crashes5
    for d in ${cull_dir}/out_*/; do
        idx=$(echo $(basename $d) | cut -d "_" -f 2);
        cp -r ${d}/default/crashes ${d}/default/backup-crashes
        afltriage -i ${d}/default/crashes -o ${out_dir}/u-crashes5/u-${idx} $STDIN --bucket-strategy first_5_frames ./triage_build/target $PH;
    done;

    cd ${out_dir}/u-crashes5
    mkdir uniques
    for dd in ./u-*; do cp ${dd}/* uniques/; done
    cd ../..
    
fi

set +x
