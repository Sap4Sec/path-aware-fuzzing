#!/bin/bash

echo "** STARTING THE FUZZING SESSION **"
set -x
./build_pcguard.sh && ./fuzz_cmplog.sh && ${AFL_PATH}/scripts/deduplicate_crashes.sh
set +x

echo "** THE FUZZING SESSION IS OVER **"
