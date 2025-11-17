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

echo "PLACEHOLDER: NO PLACEHOLDER FOR THIS SUBJ"

if [[ $3 == "-E" ]]; then
    echo "Fuzzing with -E option">>log.txt
    $AFLFUZZ -b $BIND_CPU -E 0 -t 1000+ $dict_c -i $1 -o $2 -m none -- ./target.pc &>>fuzz_E_out.dump
else
    $AFLFUZZ -b $BIND_CPU -V $FUZZING_WINDOW -t 1000+ $dict_c -i $1 -o $2 $cmplog_c -m none -- ./target.afl &>>fuzz_out.dump
fi
