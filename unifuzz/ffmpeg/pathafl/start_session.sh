#!/bin/bash

pw=$(pwd)

git clone https://github.com/yanxxd/PathAFL.git
mv PathAFL/* /home/pathafl
cd /home/pathafl
make
cd $pw

echo "** STARTING THE FUZZING SESSION **"
set -x
./fuzz_pathafl.sh
${AFL_PATH}/scripts/deduplicate_pathafl_crashes.sh

set +x
echo "** THE FUZZING SESSION IS OVER **"
