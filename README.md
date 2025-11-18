# Path-aware Fuzzing

This repository provides the source code and evaluation scripts used in the "Towards Path-aware Coverage-guided Fuzzing" paper, to appear in Proceedings of CGO 2026.

The purpose of this work is to improve coverage-guided fuzzing by introducing path-aware instrumentation: an intra-procedural execution-path-based feedback mechanism which increases sensitivity to distinct program behaviors within functions.

## Cite 
If you are referencing our work in your research, please consider using the following BibTeX entry:

<!---
TODO: will need to add the paper DOI
-->
```bibtex
@INPROCEEDINGS{Priamo-CGO26,
  author={Priamo, Giacomo and D’Elia, Daniele Cono and Payer, Mathias and Querzoni, Leonardo},
  title={Towards Path-aware Coverage-guided Fuzzing},
  booktitle = {Proceedings of the 2026 IEEE/ACM International Symposium on Code Generation and Optimization},
  publisher = {IEEE Press},
  series = {CGO '26},
  location = {Sydney, Australia},
  year={2026}
}
```

## Dependencies

This project was developed around the following toolchain and platform versions (recommended for reproduction):

- AFL++ 4.07a (included in this artifact)
- LLVM 12.0.1
- Ubuntu 20.04 (experiment platform)
- Rust 1.78.0 (required by AFLTriage)
- Python 3.8 (used by AFL++ and AFLTriage)

Other versions may work but could require adjustments to build scripts or environment variables.

Key Source Changes
------------------
The AFL++ components modified to incorporate our path-aware feedback include the following files:
- [src/afl-cc.c](src/afl-cc.c) - to insert the switch to toggle the use of our instrumentation
- [src/afl-fuzz-queue.c](src/afl-fuzz-queue.c) - to dump the favored seeds from AFL++
- [src/afl-fuzz-run.c](src/afl-fuzz-run.c) - to implement a single-calibration cycle (used by the aggressive mode of the culling script)
- [include/config.h](include/config.h) - to set the default map size and define the single-calibration cycle
- [include/envs.h](include/envs.h) - to define the new environment variables we introduced in the fuzzer
- [GNUmakefile.llvm](GNUmakefile.llvm) - to compile our analysis and transformation passes (see below) alongside AFL++

Instrumentation
------------------------
The implementation of our path-aware feedback is based on a Ball-Larus path numbering instrumentation for the LLVM IR. We adapted an [existing implementation](https://github.com/syoyo/LLVM/tree/master/lib/Transforms/Instrumentation) to instrument programs at the LLVM IR level and to integrate path counters into AFL++'s feedback loop.

The specific source files involved in the LLVM IR instrumentation for path-aware fuzzing are:
- [instrumentation/PathNumbering.cpp](instrumentation/PathNumbering.cpp) and [instrumentation/PathNumbering.h](instrumentation/PathNumbering.h) - implementing the path enumeration and numbering algorithms
- [instrumentation/afl-llvm-BL-profiling-pass.so.cc](instrumentation/afl-llvm-BL-profiling-pass.so.cc) - injecting the path profiling instrumentation into the binary and handling the fuzzer's queue management operations

UniFuzz Targets
----------------
The [unifuzz/](unifuzz/) directory contains the scripts and Docker images to reproduce the [UniFuzz](https://github.com/unifuzz) targets evaluated in the paper. Subject directories follow the layout `unifuzz/<subject>/[path|pcguard]`.

- `path`: scripts and Docker image for building and running a subject with the path-aware instrumentation provided by this repository (`path`, `cull` and `opp` fuzzers).
- `pcguard`: scripts and Docker image for building and running a subject with AFL++'s `pcguard` instrumentation (used for baseline comparisons).

Each `path`/`pcguard` sub-directory contains a `Dockerfile` to create a container instance for that specific `<fuzzer,subject>` pair.
You can run any of them by using the provided shell scripts or by executing equivalent commands inside the container. The primary contents of each benchmark sub-directory are:
- `seeds/` - initial seeds to fuzz the subject
- `triage_build/build.sh` - creates a clean, uninstrumented build used for crash triaging (AFLTriage)
- `pc_build/build_pcguard.sh` (`path/` only) - builds the target with AFL++'s `pcguard` instrumentation; used in comparative runs and by the queue culling script
- `build_image.sh` - builds the Docker image for the subject
- `run_docker.sh` - launches the Docker image as a container instance
- `build_bench.sh` (`path/` only) - pulls the UniFuzz subject and builds it with the path-aware instrumentation; then builds it with `pcguard` for comparison
- `build_pcguard.sh` (`pcguard/` only) - builds the subject with the `pcguard` instrumentation
- `Dockerfile` - container recipe for the benchmark
- `fuzz_cmplog.sh` - starts a standard AFL++ fuzzing run by invoking `afl-fuzz`
- `fuzz_enhanced.sh` (`path/` only) - helper used by the `cull` fuzzer ([scripts/fuzz-cull.sh](scripts/fuzz-cull.sh)) for dry-runs and for resuming fuzzing after culling

  1. With the `-E` argument, perform a dry-run over the queue to collect favored seeds used by the culling procedure.
  2. Start the next fuzzing round once the culling round is complete.
- `start_session.sh` wraps most of the scripts described above

### Docker Image (recommended)
We provide a Docker image for an easy way to try out our system.

#### 1. Build the base image
The base image contains the fundamental components of this system (LLVM 12, dependencies, AFL++, and AFLTriage).

```bash
docker build -t path-fuzzing -f Dockerfile .
```

#### 2.a. Direct use
You can now directly run the image you've just built:
```bash
docker run -it path-fuzzing:latest /bin/bash
```
and use it as shown in ["Standalone usage" - step #3](#fuzz).

#### 2.b. Build and test the UniFuzz subjects
Alternatively, if you want to use our scripts, please follow these steps:

0. Navigate into the desired `unifuzz/<subject>/[path/pcguard]` directory
1. Build the Docker image using the `build_image.sh` script
2. Create the container using the `run_docker.sh` script
3. Start the building and testing session by invoking `./start_session.sh`. This script will:
    1. Build the target program using `build_bench.sh` or `build_pcguard.sh`.
    2. Start the fuzzing campaign using `fuzz_cmplog.sh`.
    You can optionally pass the `-cull` parameter to `start_session.sh` to fuzz the program using our queue culling technique (path-aware fuzzing only). This invokes the queue culling script ([scripts/fuzz-cull.sh](scripts/fuzz-cull.sh)) script, which interleaves the fuzzing process with queue culling rounds and collects the results at the end of the run
    3. Invoke the crash deduplication script ([scripts/deduplicate_crashes.sh](scripts/deduplicate_crashes.sh)) to automatically derive the unique crashes* detected by the fuzzer (if present) using the [AFLTriage](https://github.com/quic/AFLTriage.git) tool

### Minimal Working Example
Here are the complete steps for running a minimal working example of our system:

1. Build the main Docker image:
```bash
docker build -t path-fuzzing -f Dockerfile .
```
2. Navigate to the [unifuzz/mp3gain/path](unifuzz/mp3gain/path) directory:
```bash
cd unifuzz/mp3gain/path
```
3. Build the dedicated Docker image: 
```bash
./build_image.sh
```
4. Run the related container:
```bash
./run_docker.sh
```
5. Configure runtime environment variables. For example:

```bash
export RUNTIME=10800  # 3 hours; default is 172800 (48 hours)
```
*Optionally, adjust `FUZZING_WINDOW_ORIG` to change the duration of culling rounds.*
```bash
export FUZZING_WINDOW_ORIG=3600  # 1 hour; default is 21600 (6 hours)
```

6. (a) Start the session, invoking one among:

```bash
./start_session.sh         # normal run
```
```bash
./start_session.sh -cull   # culling-enabled run
```

6. (b) We also provide a queue produced with the edge coverage feedback ([edge_queue.7z](unifuzz/mp3gain/path/edge_queue.7z)). You can use it to try out our opportunistic strategy (`opp` fuzzer):
```bash 
7z x edge_queue.7z
rm -rf seeds
mv edge_queue seeds
./start_session.sh         # opportunistic run
```

At the end of the session, the `afl_out_0/` directory will contain the complete results of the fuzzing campaign. The results of the crash deduplication* process (if at least 1 crash was detected) will be located in the `afl_out_0/u-crashes5` directory for a normal fuzzing run, while for a culling run the final results will be located in the `afl_out_0/u-crashes5/uniques` folder.

\**Please beware that in our work we also manually analyzed the deduplicated crashes to derive unique **bugs** (i.e., we distinguished those with a different underlying root cause), as stack hash-based crash deduplication notoriously results in bug over-/under-counting.*

These steps can be generalized to run any of the UniFuzz subjects. 

### Standalone Usage (fuzzing experts)
To run the system locally on your own machine, please refer to the following instructions.

#### 1. Building the Fuzzer
```bash
CC=clang CXX=clang++ LLVM_CONFIG=llvm-config make
```

#### 2. Building the target program
1. Before building your target program, export the following environment variables:

```bash
export AFL_PATH="/path/to/afl-fuzz" # Set this to point to the root directory of this repository
export AFL_LLVM_INSTRUMENT="classic"
export AFL_PATH_PROFILING="1"
```


```bash
export CC="${AFL_PATH}/afl-clang-fast"
export CXX="${AFL_PATH}/afl-clang-fast++"
```

2. Now you can build the program you want to fuzz using its default building system (`make`, `cmake`, `automake`, etc.)

    2.5. [Optional] As in our paper evaluation, you may also enable the [cmplog](instrumentation/README.cmplog.md) instrumentation by setting the required environment variable (`export AFL_LLVM_CMPLOG=1`), and then building the target program once again.

#### <a name="fuzz"></a> 3. Fuzzing the target program
Start the fuzzing campaign as you would normally do with AFL++:

```bash
${AFL_PATH}/afl-fuzz -t 1000+ -i <seeds> -o <output> -m none [-c <cmplog_target>] -- ./<target_program> [<placeholder>]
```

Ensure you set correct values for the `seeds` and `output` directories, and the `placeholder` argument for the target program (usually `@@`). This will run the baseline path-aware fuzzer.

##### Running the culling-enhanced fuzzer
Refer to the culling script ([scripts/fuzz-cull.sh](scripts/fuzz-cull.sh)) for the culling workflow. The script includes a `fuzz` function that you may need to adjust for your target program (for example, to set the correct input/output placeholders or execution wrapper).

## Reusability
The entire system can also be extended and customized to test any chosen program with our path-aware instrumentation (and, optionally, our queue culling procedure), as long as it is compatible with the AFL++ fuzzer. 

The first step to that end is creating the build script for the program to test. You can refer to those we provide to build the UniFuzz subjects (e.g. [unifuzz/objdump/path/build_path.sh](unifuzz/objdump/path/build_path.sh)). The crucial details to take care of are:
1. Enabling our path-aware instrumentation
```bash
export AFL_PATH_PROFILING="1"
export AFL_LLVM_INSTRUMENT="classic"
```

2. Setting AFL++ as the default compiler:
```bash
export AFL_PATH="/path/to/afl-fuzz" # Set this to point to the root directory of this repository
export CC="${AFL_PATH}/afl-clang-fast"
export CXX="${AFL_PATH}/afl-clang-fast++"
```

3. Enabling the ASan sanitizer to uncover silent memory-related bugs:
```bash
export CFLAGS="${COMMON_OPTS} -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -fsanitize=address"
export CXXFLAGS="-stdlib=libc++ ${CFLAGS}"
```

4. Adding AFL++'s compiler runtime to the `LDFLAGS`
```bash
export LDFLAGS="${AFL_PATH}afl-compiler-rt.o -Wl,--allow-multiple-definition"
```

5. Building the target binary by using its default building system (`make`, `cmake`, `automake`, etc.)

6. [Optional] Building the `cmplog` version of the binary by setting the related environment variable
```bash
export AFL_LLVM_CMPLOG=1
```

Now you can start the fuzzing campaign with AFL++ as shown in ["Standalone usage" - step #3](#fuzz).