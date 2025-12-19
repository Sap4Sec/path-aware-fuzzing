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

if [[ $PLACEHOLDER == "" ]]; then
    PH=""
    STDIN="--stdin"
else
    PH=$PLACEHOLDER
fi

cp -r ./${out_dir}/crashes/ ./${out_dir}/backup-crashes/
afltriage -i ./${out_dir}/crashes/ -o ./${out_dir}/u-crashes5 $STDIN --bucket-strategy first_5_frames ./triage_build/target $PH

set +x
