#!/bin/bash

# Part 12c: Update height corrections and atmospheric phases using multi-reference stack (using def_mod_pt)

work_dir="$1"
ref_date="$2"
rlks="$3"
azlks="$4"
ref_point="$5"

cd ipta

num_row=`cat ../int/bperp_file.txt | wc -l`
echo "number of rows in ../int/bperp_file.txt is ... $num_row"

# replace reference point values with spatially filtered values (to reduce noise)
spf_pt pt_geo pmask_single ../DEM/EQA.dem_par pdiff3 pdiff3a - 0 5 0 - $ref_point 0

# now after subtracting the atmospheric phase we should be able to use def_mod_pt with one spatial reference point
# Again we use model 1 to only estimate a height correction and to determine an update to the atmospheric phase
def_mod_pt pt - pSLC_par - itab pbase 0 pdiff3a 1 $ref_point pres4 pdh4 pddef4 punw4 psigma4 pmask4 100. -0.01 0.01 1.2 1 pdh_err4
# solution found for about 140000 elements

#pdisdt_pwr24 pt pmask4 ${ref_date}.rslc.par pdh4 1 ${ref_date}.rmli.par ave.rmli 30. 3
#pdisdt_pwr24 pt pmask4 ${ref_date}.rslc.par pdh_err4 1 ${ref_date}.rmli.par ave.rmli 10. 3
#pdisdt_pwr24 pt pmask4 ${ref_date}.rslc.par psigma4 1 ${ref_date}.rmli.par ave.rmli 1.5. 3

ras_data_pt pt pmask4 pres4 1 $num_row ave.rmli.bmp ras/pres4 2 $rlks $azlks -6.28 6.28 1 rmg.cm
#xv ras/pres4_???.bmp &
# bash ../mymontage.sh "ras/pres4_???.bmp"

# we try to avoid unwrapping errors by rewrapping followed by spatial filtering and unwrapping
# the filtering and spatial unwrapping is done in map geometry
unw_to_cpx_pt pt pmask4 pres4 - pres4.cpx
spf_pt pt_geo pmask4 ../DEM/EQA.dem_par pres4.cpx pres4.cpx.spf_geo - 0 50 1
mcf_pt pt_geo pmask4 pres4.cpx.spf_geo - - - pres4.cpx.unw - - $ref_point 0 - - ../DEM/EQA.dem_par

# check unwrapped phases
ras_data_pt pt_geo pmask4 pres4.cpx.unw 1 $num_row ../DEM/EQA.ave.rmli.bmp ras/pres4.cpx.unw 2 1 1 -6.28 6.28 1 rmg.cm 3
#xv -exp -4 ras/pres4.cpx.unw_???.bmp &
# bash ../mymontage.sh "ras/pres4.cpx.unw_???.bmp"

# --> it looks OK for all layers
# --> Hence we accept this solution

# we add it to the patm3, filter and expand it,
# to get the update atmopsheric phase patm4
rm -f patm4 ptmp2 ptmp1
lin_comb_pt pt pmask4 patm3 - pres4.cpx.unw - ptmp2 - 0.0 1. 1. 2 0
spf_pt pt_geo pmask4 ../DEM/EQA.dem_par ptmp2 ptmp1 - 2 15 1
expand_data_inpaint_pt pt_geo pmask4 ../DEM/EQA.dem_par ptmp1 pt_geo - patm4 - 0 10 4 - 0

# update heights
lin_comb_pt pt - phgt3 1 pdh4 1 phgt4 - 0.0 1. 1. 2 1
#pdisdt_pwr24 pt - ${ref_date}.rslc.par phgt4 1 ${ref_date}.rmli.par ave.rmli 200. 3

# simulate the phase corresponding to the total height correction (pdh4total)
# pdh4.sim_unw; then subtract it from the differential interferograms
lin_comb_pt pt - phgt4 1 pdem_combined 1 pdh4.total - 0.0 1. -1. 2 1
phase_sim_pt pt - pSLC_par - itab - pbase pdh4.total pdh4.sim_unw - 2 0

# we subtract the topo phase corrections as well as the estimated atmospheric path delays (patm_mod0 and patm4)
sub_phase_pt pt - pdiff - pdh4.sim_unw pdiff.0 1 0
sub_phase_pt pt - pdiff.0 - patm_mod0 pdiff.1 1 0
sub_phase_pt pt - pdiff.1 - patm4 pdiff4 1 0

# display pdiff4
ras_data_pt pt_combined - pdiff4 1 $num_row ave.rmli.bmp ras/pdiff4 0 $rlks $azlks - - 1
#xv -exp -2 ras/pdiff4_???.bmp &
# bash ../mymontage.sh "ras/pdiff4_???.bmp"

# --> the differential interferograms are quite flat (at somewhat different average phase levels). Some deviations are observed in the Moosfluh landslide area, possibly deformation phase even over these short intervals considered

