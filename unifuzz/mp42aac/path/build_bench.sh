#!/bin/bash

bash build_path.sh &>dbg && cp -R SRC pc_build/ && cd pc_build/ && bash build_pcguard.sh -- -nc && cp target.afl ../target.pc && cd ..
