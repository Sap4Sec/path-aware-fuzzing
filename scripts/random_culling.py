#!/usr/bin/python

import os
import sys
import shutil
import numpy as np
from datetime import datetime

if len(sys.argv) != 3: 
    print(f"Usage: {sys.argv[0]} <in_dir> <out_dir>")
    sys.exit(1)

in_dir = sys.argv[1]
out_dir = sys.argv[2]

culling_percents = [0.84,0.86,0.9,0.91,0.92,0.93,0.95,0.97,0.98]

# --- Seeding ---
seed_timestamp = datetime.now().timestamp()
print(f"Seed (timestamp): {seed_timestamp}")

# NumPy's default_rng requires an integer seed.
# We convert the float timestamp to an int, preserving microsecond-level detail.
seed_int = int(seed_timestamp * 1_000_000)

# Initialize NumPy's modern random number generator
rng = np.random.default_rng(seed_int)

# --- Culling ---
testcases = []
#1) Collect all the test cases from the input dir
for f in os.listdir(in_dir):
    jn = os.path.join(in_dir, f)
    if not os.path.isfile(jn): continue
    testcases.append(jn)

print(f"Corpus before: {len(testcases)}")

#2) Select the % of tescases to cull
cull_percs_tmp = culling_percents[:]
cull_perc = rng.choice(cull_percs_tmp)  # <-- Use NumPy's generator

print(f"Culling perc: {cull_perc}")

#3) Compute the percentage of testcases removed
to_rem = int(len(testcases)*cull_perc)
print(f"Going to remove {to_rem} testcases")

# Use NumPy's choice for sampling without replacement
tmp_rem = rng.choice(testcases, to_rem, replace=False)

print(f"Delta (corpus): {len(tmp_rem)}")

tmp_rem_set = set(tmp_rem)
tc = [t for t in testcases if t not in tmp_rem_set]

#4) Move the non-culled seeds to the new input directory
for t in tc:
    shutil.copy(t, out_dir)

print(f"Corpus after: {len(tc)}")