#!/bin/bash

# Test step 3: update the solution  using def_mod_pt

work_dir="$1"
ref_date="$2"
rlks="$3"
azlks="$4"

cd ${work_dir}/ipta_test
# Test step 3A: update phgt, patm using def_mod_pt with one-dimensional regression

# orbital and terrain phase (using phase_sim_orb)
phase_sim_orb_pt pt - pSLC_par - itab - phgt1 psim_unw ${ref_date}.rslc.par -

# we subtract the topo phase corrections as well as the estimated atmospheric path delays
# (patm_mod and patm)
sub_phase_pt pt - pint - psim_unw pdiff00 1 0
sub_phase_pt pt - pdiff00 - patm_mod pdiff0 1 0
sub_phase_pt pt - pdiff0 - patm pdiff1 1 0

num_row=`cat ../int/bperp_file.txt | wc -l`
echo "number of rows in ../int/bperp_file.txt is ... $num_row"

# display pdiff1
ras_data_pt pt pmask1 pdiff1 1 $num_row ave.rmli.bmp ras/pdiff1 0 $rlks $azlks - -
#xv -exp -2 ras/pdiff1_???.bmp &
bash ../mymontage.sh "ras/pdiff1_???.bmp"

# --> overall the differential interferograms are again quite flat (but at somewhat different average phase levels)

# replace reference point values with spatially filtered values (to reduce noise)
ref_point_rev=`grep "1" prox_prt.txt | awk -F" " '{print $2}'`
spf_pt pt_geo pmask1 ../DEM/EQA.dem_par pdiff1 pdiff1a - 0 15 0 - $ref_point_rev 0

# We use model 1 to only estimate a height correction and to determine an update to the atmospheric phase
def_mod_pt pt - pSLC_par - itab pbase 0 pdiff1a 1 $ref_point_rev pres2 pdh2 - punw2 psigma2 pmask2 200. -0.01 0.01 1.4 1 pdh_err2
# solution found for 2137443 elements

# visualize estimated height correction and update point heights
#pdisdt_pwr24 pt pmask2 ${ref_date}.rslc.par pdh2 1 ${ref_date}.rmli.par ave.rmli 100. 3
#pdisdt_pwr24 pt pmask2 ${ref_date}.rslc.par pdh_err2 1 ${ref_date}.rmli.par ave.rmli 10. 3

# the height corrections over some glacier areas are about -30m due to melting of the ice.
# For other areas the height corrections are mainly between about -10m and + 10m.
# we update the heights
lin_comb_pt pt - phgt1 1 pdh2 1 phgt2 - 0.0 1. 1. 2 1
#pdisdt_pwr24 pt - ${ref_date}.rslc.par phgt2 1 ${ref_date}.rmli.par ave.rmli 200. 3

# visualize residual phase and update patm
num_row=`cat ../int/bperp_file.txt | wc -l`
echo "number of rows in ../int/bperp_file.txt is ... $num_row"
ras_data_pt pt pmask2 pres2 1 $num_row ave.rmli.bmp ras/pres2 2 $rlks $azlks -6.28 6.28 1 rmg.cm
#xv ras/pres2_???.bmp &
bash ../mymontage.sh "ras/pres2_???.bmp"

# we correct potential unwrapping errors by rewrapping followed by spatial filtering and unwrapping
# the filtering and spatial unwrapping is done in map geometry
unw_to_cpx_pt pt pmask2 pres2 - pres2.cpx
fspf_pt pt_geo pmask2 ../DEM/EQA.dem_par pres2.cpx pres2.cpx.spf_geo - 0 50 1
mcf_pt pt_geo pmask2 pres2.cpx.spf_geo - - - pres2.cpx.unw - - $ref_point_rev 0 - - ../DEM/EQA.dem_par

# check unwrapped phases
ras_data_pt pt_geo pmask2 pres2.cpx.unw 1 $num_row ../DEM/EQA.ave.rmli.bmp ras/pres2.cpx.unw 2 1 1 -6.28 6.28 1 rmg.cm
#xv -exp -4 ras/pres2.cpx.unw_???.bmp &
bash ../mymontage.sh "ras/pres2.cpx.unw_???.bmp"

# --> looks mostly OK, --> accepted

# we add pres2.cpx.unw to the patm, filter and expand it, to get the update atmopsheric phase patm2
rm -f patm2 ptmp2 ptmp1
lin_comb_pt pt - patm - pres2.cpx.unw - ptmp2 - 0.0 1. 1. 2 0
spf_pt pt_geo pmask2 ../DEM/EQA.dem_par ptmp2 ptmp1 - 2 15 1
expand_data_inpaint_pt pt_geo pmask2 ../DEM/EQA.dem_par ptmp1 pt_geo - patm2 - 0 10 4 - 0

# we display the atmospheric phase patm2 (after patm_mod1 was subtracted)
ras_data_pt pt_geo - patm2 1 $num_row ../DEM/EQA.ave.rmli.bmp ras/patm2 2 1 1 -6.28 6.28 1 rmg.cm
#xv -exp -4 ras/patm2_???.bmp &
bash ../mymontage.sh "ras/patm2_???.bmp"

