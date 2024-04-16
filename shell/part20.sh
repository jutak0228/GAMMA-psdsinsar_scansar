#!/bin/bash

# Test step 4: add up unwrapped phase terms to total unwrapped multi-ref DInSAR phase

work_dir="$1"
ref_date="$2"

cd ${work_dir}/ipta_test

# At this stage we want to conclude determining the unwrapped phases
# using iterations of def_mod_pt.
# We get the total unwrapped phases of the differential interferogram
# stack by adding up the different components:
# pdiff00.unw = punw4 + patm_mod + patm3 (except for the offset introduced by the spatial filtering of the reference point

rm -f ptmp1 ptmp2 ptmp3
sub_phase_pt pt pmask4 punw4 - patm_mod ptmp2 0 1
sub_phase_pt pt pmask4 ptmp2 - patm3 pdiff00.unw 0 1

# check correspondence of pdiff and pdiff.unw (to make sure no phase term was lost)
rm -f ptmp1 ptmp2 ptmp3
sub_phase_pt pt pmask4 pdiff00 - pdiff00.unw  ptmp1 1 0
#pdismph_pwr24 pt pmask4 ${ref_date}.rslc.par ptmp1 21 ${ref_date}.rmli.par ave.rmli 3

# --> the summed up phase corresponds well to the pdiff00 phase
/bin/cp pdiff00.unw pdiff.unw1

# --> The unwrapped differential interferometric phases for the multi-reference stack are determined.
#     Furthermore, height corrections were determined and unwrapped differential
#     interferometric phases after subtracting the height correction effect (pdiff.unw1)
#     Furthermore, the mask pmask4 that includes only point with "good statistics" in
#     the multi-reference stack regression analysis was determined. In the regression
#     analysis a linear model was used but only very short intervals are considered. So
#     to a certain degree non-uniform motion will still be part of the solution (as long
#     as the behaviour over the very short intervals can be reasonably well modelled with a linear model).

