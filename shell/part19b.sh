#!/bin/bash

# Test step 3B: update phgt, patm using def_mod_pt with one-dimensional regression

work_dir="$1"
ref_date="$2"
rlks="$3"
azlks="$4"

cd ${work_dir}/ipta_test

# we subtract the topo phase as well as the estimated atmospheric path delays
phase_sim_orb_pt pt - pSLC_par - itab - phgt2 psim_unw2 ${ref_date}.rslc.par -
sub_phase_pt pt - pint - psim_unw2 pdiff00 1 0
sub_phase_pt pt - pdiff00 - patm_mod pdiff0 1 0
sub_phase_pt pt - pdiff0 - patm2 pdiff2 1 0

# replace reference point values with spatially filtered values (to reduce noise) and run def_mod_pt
ref_point_rev=`grep "1" prox_prt.txt | awk -F" " '{print $2}'`
spf_pt pt_geo pmask2 ../DEM/EQA.dem_par pdiff2 pdiff2a - 0 15 0 - $ref_point_rev 0

# We use model 1 to only estimate a height correction and to determine an update
# to the atmospheric phase
def_mod_pt pt - pSLC_par - itab pbase 0 pdiff2a 1 $ref_point_rev pres3 pdh3 pddef3 punw3 psigma3 pmask3 100. -0.01 0.01 1.3 1 pdh_err3
# solution found for about 1708851 elements

# visualize estimated height correction and update point heights
#pdisdt_pwr24 pt pmask3 ${ref_date}.rslc.par pdh3 1 ${ref_date}.rmli.par ave.rmli 100. 3
#pdisdt_pwr24 pt pmask3 ${ref_date}.rslc.par pdh_err3 1 ${ref_date}.rmli.par ave.rmli 10. 3

# the height corrections are now much smaller.
# we update the heights
lin_comb_pt pt - phgt2 1 pdh3 1 phgt3 - 0.0 1. 1. 2 1
#pdisdt_pwr24 pt - ${ref_date}.rslc.par phgt3 1 ${ref_date}.rmli.par ave.rmli 200. 3

# visualize residual phase and update patm
num_row=`cat ../int/bperp_file.txt | wc -l`
echo "number of rows in ../int/bperp_file.txt is ... $num_row"
ras_data_pt pt pmask3 pres3 1 $num_row ave.rmli.bmp ras/pres3 2 $rlks $azlks -6.28 6.28 1 rmg.cm
#xv ras/pres3_???.bmp &
bash ../mymontage.sh "ras/pres3_???.bmp"

# we correct potential unwrapping errors by rewrapping followed by spatial filtering and unwrapping
# the filtering and spatial unwrapping is done in map geometry
unw_to_cpx_pt pt pmask3 pres3 - pres3.cpx
fspf_pt pt_geo pmask3 ../DEM/EQA.dem_par pres3.cpx pres3.cpx.spf_geo - 0 50 1
mcf_pt pt_geo pmask3 pres3.cpx.spf_geo - - - pres3.cpx.unw - - $ref_point_rev 0 - - ../DEM/EQA.dem_par

# check unwrapped phases
ras_data_pt pt_geo pmask3 pres3.cpx.unw 1 $num_row ../DEM/EQA.ave.rmli.bmp ras/pres3.cpx.unw 2 1 1 -6.28 6.28 1 rmg.cm
#xv -exp -4 ras/pres3.cpx.unw_???.bmp &
bash ../mymontage.sh "ras/pres3.cpx.unw_???.bmp"

# --> looks mostly OK, --> accepted

# we add pres3.cpx.unw to the patm, filter and expand it,
# to get the update atmopsheric phase patm3
rm -f patm3 ptmp2 ptmp1
lin_comb_pt pt - patm2 - pres3.cpx.unw - ptmp2 - 0.0 1. 1. 2 0
spf_pt pt_geo pmask3 ../DEM/EQA.dem_par ptmp2 ptmp1 - 2 15 1
expand_data_inpaint_pt pt_geo pmask3 ../DEM/EQA.dem_par ptmp1 pt_geo - patm3 - 0 10 4 - 0

# we display the atmospheric phase patm2 (after patm_mod1 was subtracted)
ras_data_pt pt_geo - patm3 1 $num_row ../DEM/EQA.ave.rmli.bmp ras/patm3 2 1 1 -6.28 6.28 1 rmg.cm
#xv -exp -4 ras/patm3_???.bmp &
bash ../mymontage.sh "ras/patm3_???.bmp"

