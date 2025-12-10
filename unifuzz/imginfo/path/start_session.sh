#!/bin/bash

echo "** STARTING THE FUZZING SESSION **"
set -x
./build_bench.sh 
if [[ $1 == "-cull" ]]; then
    echo "RUNNING FUZZING+CULLING SESSION"
    mkdir afl_out_${BIND_CPU}
    ${AFL_PATH}/scripts/fuzz-cull.sh
else 
    echo "RUNNING FUZZING SESSION"
    ./fuzz_cmplog.sh
fi
${AFL_PATH}/scripts/deduplicate_crashes.sh

set +x
echo "** THE FUZZING SESSION IS OVER **"
