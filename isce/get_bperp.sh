#!/bin/bash -vx
# collect perpendicular component of baseline ("bperp") for each insar pair
# 2021/06/17 Kurt Feigl

echo "YYYYMMDD1, YYYYMMDD2, BperpInMeters" > bperp.csv
grep Bperp `find baselines -name "*.txt"` | sed 's%/% %g' | sed 's/_/ /g' | awk '{printf("%8d,   %8d, %20.12f\n",$3,$4,$7)}' >> bperp.csv
