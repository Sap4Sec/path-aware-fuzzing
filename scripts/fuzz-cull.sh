#!/bin/bash

# Wrapper script to run queue culling-enhanced path aware fuzzer.

TOTAL_RUNTIME=$RUNTIME  # Total runtime of the fuzzing campaign
export FUZZING_WINDOW=$FUZZING_WINDOW_ORIG # Duration of a fuzzing round
FUZZING_ROUNDS=$((TOTAL_RUNTIME / FUZZING_WINDOW))
CURR_ITER=0
echo "Going to fuzz for $FUZZING_ROUNDS rounds (=TOTAL_RUNTIME=${TOTAL_RUNTIME} - FUZZING_WINDOW=${FUZZING_WINDOW})"

# Starts the standard fuzzing round
function fuzz { 
    if [[ $# != 2 ]]; then
        echo "Usage: $0 <in_dir> <out_dir>"
        exit 3
    fi

    bash fuzz_enhanced.sh $1 $2
}

# This function performs the queue culling operations by feeding the current 
# fuzzing round's queue to a pcguard-istrumented binary to collect the favored seeds
# and then copies them to the seeds folder for the next fuzzing round
function fuzz_cull { 
    if [[ $# != 2 ]]; then
        echo "Usage: $0 <in_dir> <out_dir>"
        exit 3
    fi

    #1) Fuzz the contents of $1/default/queue with -E 0 to perform a dry run
    #2) Create $2 (the output directory)
    #3) Copy the favored test cases to $2

    idx=$(echo $2 | cut -d "_" -f 2)
    tmp_dir="fuzz_tmp_out_${idx}"

    d1=$(date +%s)
    mv ${1}/default/queue ./test_in
    d2=$(date +%s)
    delta1=$((d2 - d1))
    echo "Delta (mv ${1}/default/queue ./test_in): ${delta1}" >>log.txt

    # Aggressive culling mode (to be used when the dry run takes several minutes or hours).
    # Performs a pre-processing of the queue that removes the test cases deemed as 
    # redundant by the path-aware fuzzer
    if [[ $AGGRESSIVE_CULLING == 1 ]]; then
        echo "Removing path redudants" >>log.txt

        if [[ ! -e ./test_in/.state/redundant_edges/  ]]; then 
            echo "redundant_edges folder does NOT exist! Will not remove path redundants" >>log.txt
        elif [[ $(ls -1 ./test_in/.state/redundant_edges/ | wc -l) == 0 ]]; then
            echo "redundant_edges folder is empty! Will not remove path redundants" >>log.txt
        else
            echo "Initial queue size: $(ls -1 ./test_in/ | wc -l) - Redundants: $(ls -1 ./test_in/.state/redundant_edges/ | wc -l)" >>log.txt
            for f in test_in/.state/redundant_edges/*; do
                bn=$(basename $f) && rm test_in/${bn}
            done
        fi
        echo "New queue size: $(ls -1 ./test_in/ | wc -l)" >>log.txt
        export CULL_FAST_CAL=1
    fi

    rm -rf test_in/.state

    # This is required to instruct AFL++ to dump the favored seeds to file
    export PATH_DUMP_FAVORED=1

    d3=$(date +%s)
    bash fuzz_enhanced.sh test_in $tmp_dir -E
    d4=$(date +%s)
    delta2=$((d4 - d3))
    echo "Delta (afl-fuzz -E): ${delta2}" >>log.txt

    unset PATH_DUMP_FAVORED

    if [[ $AGGRESSIVE_CULLING == 1 ]]; then
        unset CULL_FAST_CAL
    fi

    mkdir $2

    echo "Culling non-favored seeds" >>log.txt
    d5=$(date +%s)
    cat seeds.favored | cut -d "/" -f 4 > seeds.favored.names
    d6=$(date +%s)
    delta3=$((d6 - d5))
    echo "Delta (cat seeds.favored [...]): ${delta3}" >>log.txt
    
    echo "Putting favored into $2"
    
    d7=$(date +%s)
    while read line; do cp ${tmp_dir}/default/queue/${line} $2; done < seeds.favored.names
    d8=$(date +%s)
    delta4=$((d8 - d7))
    echo "Delta (while read [...] do cp [...] <seeds.favored): ${delta4}" >>log.txt

    rm -rf test_in
}

# Main fuzzing loop that interleaves the fuzzing campaign
# with the queue culling rounds
function main_loop {
    remaining_fuzztime=$RUNTIME
    out_dir="./out_0"

    fuzz_iters=1

    delta_accum=0

    echo "{$(date)} [Fuzz] Start initial fuzzing run (Iteration: ${fuzz_iters}/${FUZZING_ROUNDS})" >>log.txt
    d1=$(date +%s)

    set -x
    fuzz ./seeds/ $out_dir
    set +x

    remaining_fuzztime=$((remaining_fuzztime-FUZZING_WINDOW_ORIG))

    d2=$(date +%s)
    delta=$((d2 - d1))
    echo "{$(date)} [Fuzz] End fuzzing run" >>log.txt
    #echo "Delta(fuzz time): $delta" >> log.txt
    tput=$(cat ${out_dir}/default/fuzzer_stats | grep execs_per_sec | cut -d ":" -f 2 | tr -d " ")
    echo "Throughput: $tput" >>log.txt
    cycles=$(cat ${out_dir}/default/fuzzer_stats | grep cycles_done | cut -d ":" -f 2 | tr -d " ")
    echo "Cycles: $cycles" >>log.txt

    export AFL_FAST_CAL=1
    export AFL_CMPLOG_ONLY_NEW=1

    i=0

    fuzz_out=$out_dir

    echo "Entering loop"
    while [ 1 ]; do
        i=$((i + 1))
        cmin_out="in_${i}"

        echo "{$(date)} [CULLING] Start" >>log.txt
        corpus_before=$(cat ${fuzz_out}/default/fuzzer_stats | grep corpus_count | cut -d ":" -f 2 | tr -d " ")
        echo "Corpus before: $corpus_before" >>log.txt
        #d3=$(date +%s)

        d3=$(date +%s)
        fuzz_cull $fuzz_out $cmin_out
        d4=$(date +%s)
        delta2=$((d4 - d3))
        echo "Delta(cull time): $delta2" >>log.txt

        if [[ $REMOVE_CULLTIME == 1 ]]; then
            #export FUZZING_WINDOW=$((FUZZING_WINDOW_ORIG - $delta2))
            delta_accum=$((delta_accum + $delta2))
            echo "Accumulated culltime: $delta_accum" >>log.txt
            if [[ $fuzz_iters == $((FUZZING_ROUNDS-1)) ]]; then
                export FUZZING_WINDOW=$((FUZZING_WINDOW_ORIG - delta_accum))
                echo "Last round reached! Adjusted fuzzing window: $FUZZING_WINDOW" >>log.txt
                if [[ $FUZZING_WINDOW -lt 2 ]]; then
                    export FUZZING_WINDOW=1
                fi
            elif [[ $delta_accum -gt $remaining_fuzztime ]]; then
                echo "Accumulated culltime is greater than the remaining fuzzing time" >>log.txt
                export FUZZING_WINDOW=1
            fi
        fi

        corpus_after=$(ls -1 $cmin_out | wc -l)
        echo "Corpus after: $corpus_after" >>log.txt
        echo "Delta(corpus): $((corpus_before - corpus_after))" >>log.txt
        echo "{$(date)} [CULLING] End" >>log.txt

        fuzz_out="out_${i}"

        fuzz_iters=$((fuzz_iters + 1))

        echo "{$(date)} [FUZZ] Start (Iteration: ${fuzz_iters}/${FUZZING_ROUNDS})" >>log.txt
        d5=$(date +%s)

        set -x
        fuzz $cmin_out $fuzz_out
        set +x

        remaining_fuzztime=$((remaining_fuzztime-FUZZING_WINDOW_ORIG))
        echo "Remaining fuzztime: $remaining_fuzztime">>log.txt

        d6=$(date +%s)
        delta3=$((d6 - d5))
        #echo "Delta(fuzz time): $delta3" >> log.txt
        echo "{$(date)} [FUZZ] End" >>log.txt
        tput=$(cat ${fuzz_out}/default/fuzzer_stats | grep execs_per_sec | cut -d ":" -f 2 | tr -d " ")
        echo "Throughput: $tput" >>log.txt
        cycles=$(cat ${out_dir}/default/fuzzer_stats | grep cycles_done | cut -d ":" -f 2 | tr -d " ")
        echo "Cycles: $cycles" >>log.txt        

        if [ $fuzz_iters -eq $FUZZING_ROUNDS ]; then
            break
        fi
    done
}

rm -rf out*
echo "Culling strategy: FAVORED seeds"

# Aggressive culling toggle: use when the culling step takes too long
if [[ $AGGRESSIVE_CULLING == 1 ]]; then
    echo "AGGRESSIVE CULLING is ENABLED!"
    echo "AGGRESSIVE CULLING is ENABLED!" >>log.txt
fi
if [[ $REMOVE_CULLTIME == 1 ]]; then
    echo "REMOVE CULLTIME is ENABLED, will remove the accumulated culling time deltas from the final round"
    echo "REMOVE CULLTIME is ENABLED, will remove the accumulated culling time deltas from the final round" >>log.txt
fi

echo "{$(date)} *** START ***" >log.txt
main_loop
echo "{$(date)} *** END ***" >>log.txt

set +x
echo "Starting data collection"
set -x
strat="f"
rtime="6"
dirname="${strat}${rtime}_${BIND_CPU}"
mkdir $dirname && mv in_* $dirname && mv out_* $dirname && cp log.txt $dirname && zip -r -q ${dirname}.zip $dirname && mv ${dirname}.zip "afl_out_${BIND_CPU}/"
set +x
