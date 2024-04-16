#!/bin/bash

# Part 13: Update height corrections and atmospheric phases using multi-reference stack (using def_mod_pt)
# also estimate a deformation rate (not precise because done based on short intervals, but relevant as an
# improvement of the regression fit).

work_dir="$1"
ref_date="$2"
rlks="$3"
azlks="$4"
ref_point="$5"

cd ipta

num_row=`cat ../int/bperp_file.txt | wc -l`
echo "number of rows in ../int/bperp_file.txt is ... $num_row"

# replace reference point values with spatially filtered values (to reduce noise)
spf_pt pt_geo pmask_single ../DEM/EQA.dem_par pdiff4 pdiff4a - 0 5 0 - $ref_point 0

# run again def_mod_pt using model 2
def_mod_pt pt - pSLC_par - itab pbase 0 pdiff4a 1 $ref_point pres5 pdh5 pddef5 punw5 psigma5 pmask5 10. -0.15 0.15 1.2 2 pdh_err5 pdef_err5
# solution found for about 143000 elements

#pdisdt_pwr24 pt pmask5 ${ref_date}.rslc.par pdh5 1 ${ref_date}.rmli.par ave.rmli 100. 3
#pdisdt_pwr24 pt pmask5 ${ref_date}.rslc.par pddef5 1 ${ref_date}.rmli.par ave.rmli 0.5 3
#pdisdt_pwr24 pt pmask5 ${ref_date}.rslc.par pddef5 1 ${ref_date}.rmli.par ave.rmli 0.2 3
#pdisdt_pwr24 pt pmask5 ${ref_date}.rslc.par pddef5 1 ${ref_date}.rmli.par ave.rmli 0.05 3
#pdisdt_pwr24 pt pmask5 ${ref_date}.rslc.par psigma5 1 ${ref_date}.rmli.par ave.rmli 1.5. 3
#pdisdt_pwr24 pt pmask5 ${ref_date}.rslc.par pdh_err5 1 ${ref_date}.rmli.par ave.rmli 10. 3
#pdisdt_pwr24 pt pmask5 ${ref_date}.rslc.par pdef_err5 1 ${ref_date}.rmli.par ave.rmli 0.1 3

# --> there are many small height corrections < 1m but also some large ones
# --> there are areas with predominantly small pdef estimates but other areas have noisy high estimates > 10cm/year
#     The statistical error of the deformation rate estimation (pdef_err5)
#     is high because of the short time intervals considered in the pairs of
#     the multi-reference stack.

ras_data_pt pt pmask5 pres5 1 $num_row ave.rmli.bmp ras/pres5 2 $rlks $azlks -6.28 6.28 1 rmg.cm
#xv ras/pres5_???.bmp &
# bash ../mymontage.sh "ras/pres5_???.bmp"

# --> unwrapping looks correct; punw5 can be used as unwrapped phase

# At this stage we want to conclude determining the unwrapped phases.
# We get the total unwrapped phases of the differential interferogram stack by adding up the differnt components:
# pdiff.unw = punw5 + pdh4.sim_unw + patm_mod0 + patm4 (except for the offset introduced by the spatial filtering
#     of the reference point

# We sum up punw5 + pdh4.sim_unw + patm_mod0 + patm4 to get unwrapped phase of pdiff
rm -f ptmp1 ptmp2 ptmp3
sub_phase_pt pt pmask5 punw5 - pdh4.sim_unw ptmp1 0 1
sub_phase_pt pt pmask5 ptmp1 - patm_mod0 ptmp2 0 1
sub_phase_pt pt pmask5 ptmp2 - patm4 pdiff.unw 0 1

# check correspondence of pdiff and pdiff.unw  (to make sure no phase term was lost)
unw_to_cpx_pt pt pmask5 pdiff.unw - pdiff.unw.cpx
# pdis2mph_pwr pt pmask5 20190809.rslc.par pdiff 21 pdiff.unw.cpx 21 20190809.rmli.par ave.rmli

rm -f ptmp1 ptmp2 ptmp3
sub_phase_pt pt pmask5 pdiff - pdiff.unw  ptmp1 1 0
# pdismph_pwr pt pmask5 20190809.rslc.par ptmp1 21 20190809.rmli.par ave.rmli

# --> the summed up phase corresponds well to the pdiff phase

# accept pdh4.total as the height correction and pdiff.unw as the unwrapped phase subtract the phase related to the total height correction from pdiff.unw
# --> pdiff.unw1 0 0

sub_phase_pt pt pmask5 pdiff.unw - pdh4.sim_unw pdiff.unw1 0 0

# --> The unwrapped differential interferometric phases for the multi-reference stack are determined.
#     Furthermore, height corrections were determined and unwrapped differential
#     interferometric phases after subtracting the height correction effect (pdiff.unw1)
#     Furthermore, the mask pmask5 that includes only point with "good statistics" in
#     the multi-reference stack regression analysis was determined. In the regression
#     analysis a linear model was used but only very short intervals are considered. So
#     to a certain degree non-uniform motion will still be part of the solution (as long
#     as the behaviour over the very short intervals can be reasonably well modelled with a linear model).

