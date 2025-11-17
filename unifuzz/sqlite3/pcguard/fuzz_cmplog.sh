#!/bin/bash

export AFL_PATH="/home/afl/"
export AFLFUZZ="${AFL_PATH}/afl-fuzz"

dict="$(find . -maxdepth 1 -name *.dict | xargs echo)"
cmplog="$(find . -maxdepth 1 -name *.cmplog | xargs echo)"

if [[ $dict != "" ]]; then
    dict_c="-x ${dict}"
fi
if [[ $cmplog != "" ]]; then 
    cmplog_c="-c $cmplog"
fi

echo $dict $dict_c $cmplog $cmplog_c

echo "PLACEHOLDER: NO PLACEHOLDER FOR THIS SUBJ"

$AFLFUZZ -b $BIND_CPU -V $RUNTIME -t 1000+ $dict_c -i ./seeds/ -o "afl_out_${BIND_CPU}" $cmplog_c -m none -- ./target.afl
