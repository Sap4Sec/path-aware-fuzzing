#!/bin/bash

echo "** STARTING THE FUZZING SESSION **"
set -x
./build_bench.sh 
if [[ $1 == "-cull" ]]; then
    echo "RUNNING FUZZING+CULLING SESSION"
    mkdir afl_out_${BIND_CPU}
    /home/afl/scripts/fuzz-cull.sh
else 
    echo "RUNNING FUZZING SESSION"
    ./fuzz_cmplog.sh
fi
/home/afl/scripts/deduplicate_crashes.sh

set +x
echo "** THE FUZZING SESSION IS OVER **"
