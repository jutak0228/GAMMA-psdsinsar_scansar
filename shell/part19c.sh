#!/bin/bash

# Test step 3C: last iteration, don't update terms but just use unwrapped phase; we use again the one-dimensional regression
#               but alternatively a two-dimensional regression could also be used

work_dir="$1"
ref_date="$2"
rlks="$3"
azlks="$4"

cd ${work_dir}/ipta_test

# we subtract the topo phase as well as the estimated atmospheric path delays
phase_sim_orb_pt pt - pSLC_par - itab - phgt3 psim_unw3 ${ref_date}.rslc.par -
sub_phase_pt pt - pint - psim_unw3 pdiff00 1 0
sub_phase_pt pt - pdiff00 - patm_mod pdiff0 1 0
sub_phase_pt pt - pdiff0 - patm3 pdiff3 1 0

# replace reference point values with spatially filtered values (to reduce noise)
ref_point_rev=`grep "1" prox_prt.txt | awk -F" " '{print $2}'`
spf_pt pt_geo pmask3 ../DEM/EQA.dem_par pdiff3 pdiff3a - 0 15 0 - $ref_point_rev 0

# run again def_mod_pt using model 1 or 2
def_mod_pt pt - pSLC_par - itab pbase 0 pdiff3a 1 $ref_point_rev pres4 pdh4 pddef4 punw4 psigma4 pmask4 10. -0.01 0.01 1.2 1 pdh_err4 pdef_err4
# solution found for about 1308056 elements

# mkdir tmp
# def_mod_pt pt - pSLC_par - itab pbase 0 pdiff3a 1 3796486 tmp/pres4 tmp/pdh4 tmp/pddef4 tmp/punw4 tmp/psigma4 tmp/pmask4 10. -0.1 0.1 1.2 2 tmp/pdh_err4 tmp/pdef_err4
# solution found for about 1343388 elements

# pdisdt_pwr24 pt pmask4 20190809.rslc.par tmp/pdh4 1 20190809.rmli.par ave.rmli 100. 3
# pdisdt_pwr24 pt pmask4 20190809.rslc.par tmp/pddef4 1 20190809.rmli.par ave.rmli 0.2 3
# pdisdt_pwr24 pt pmask4 20190809.rslc.par tmp/pddef4 1 20190809.rmli.par ave.rmli 0.05 3
#pdisdt_pwr24 pt pmask4 ${ref_date}.rslc.par pdh4 1 ${ref_date}.rmli.par ave.rmli 100. 3
#pdisdt_pwr24 pt pmask4 ${ref_date}.rslc.par psigma4 1 ${ref_date}.rmli.par ave.rmli 1.5. 3
#pdisdt_pwr24 pt pmask4 ${ref_date}.rslc.par pdh_err4 1 ${ref_date}.rmli.par ave.rmli 10. 3
#pdisdt_pwr24 pt pmask4 ${ref_date}.rslc.par pdef_err4 1 ${ref_date}.rmli.par ave.rmli 0.1 3

# --> only for few elements the height correction is larger than 1.0m
# --> the estimated deformation rate does not show much spatially consistent
#     non-zero values but a log of noise. The deformation signal was
#     probably added to the atmospheric phase estimation due to the small
#     spatial filters used to estimate the atmospheric phase.
#     The statistical error of the deformation rate estimation (pdef_err5)
#     is high because of the short time intervals considered in the pairs of
#     the multi-reference stack.

num_row=`cat ../int/bperp_file.txt | wc -l`
echo "number of rows in ../int/bperp_file.txt is ... $num_row"
ras_data_pt pt pmask4 pres4 1 $num_row ave.rmli.bmp ras/pres4 2 $rlks $azlks -6.28 6.28 1 rmg.cm
#xv ras/pres4_???.bmp &
bash ../mymontage.sh "ras/pres4_???.bmp"

# --> unwrapping looks correct; punw4 can be used as unwrapped phase

