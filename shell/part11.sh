#!/bin/bash

############################################################################################

# Parts 11 to 13 are performed to unwrap the differential phase, estimate the atmospheric phases, calculate an height correction to the DEM-derived point heights, and calculate a mask that discards decorrelated points

# Due to the steep topography, we filter and unwrap in map coordinates.
# This avoids having values with very different terrain heights (and consequently very different atmospheric phases) next to each other.

############################################################################################

# Part 11: Determine atmospheric phases using multi-reference stack (using multi_def_pt)

work_dir="$1"
ref_date="$2"
rlks="$3"
azlks="$4"
ref_point="$5"

cd ipta

num_row=`cat ../int/bperp_file.txt | wc -l`
echo "number of rows in ../int/bperp_file.txt is ... $num_row"

# rename files (or copy these from ../results)
/bin/cp pt_combined pt
/bin/cp pdiff_combined pdiff
/bin/cp pbase.orbit pbase

# calculate point list in map coordinates
pt2geo pt - ${ref_date}.rslc.par - pdem_combined ../DEM/EQA.dem_par ../DEM/${ref_date}.diff_par $rlks $azlks pt_geo plat_lon pmapll phgt_wgs84 pmask_dem

# visualize
#pdisdt_pwr24_map pt_geo - ../DEM/EQA.dem_par pdem_combined 1 ../DEM/EQA.ave.rmli 200.0 1

# generate structure containing all SLC parameter files (and stack of SLC values)
SLC2pt SLC_tab pt - pSLC_par pSLC -

# replace reference point values with spatially filtered value (to reduce noise)
spf_pt pt_geo pmask_single ../DEM/EQA.dem_par pdiff pdiffa - 0 5 0 - $ref_point 0

# run multi_def_pt using model 1 to only estimate a height correction, assuming no deformation
# (assuming there are not deformations is acceptable as the intervals considered are short,
# nevertheless for really fast deformation with cm/month rates this can be a limitation and will result in spatial gaps)
# we use high thresholds to keep as many points as possible
multi_def_pt pt - pSLC_par - itab pbase 0 pdiffa 1 $ref_point pres0 pdh0 - punw0 psigma0 pmask0 200. -0.01 0.01 250 1.5 1.2 1 0 1
# solution found for about 150000 elements

# visualize / check this solution
#pdisdt_pwr24 pt pmask0 ${ref_date}.rslc.par pdh0 1 ${ref_date}.rmli.par ave.rmli 100. 2
#pdisdt_pwr24 pt pmask0 ${ref_date}.rslc.par psigma0 1 ${ref_date}.rmli.par ave.rmli 1.5. 2
# -->
# height correction up to < -100m (related to glacier melting)
# square patterns visible, there are probably phase unwrapping errors

# visualize residuals
ras_data_pt pt pmask0 pres0 1 $num_row ave.rmli.bmp ras/pres0 2 $rlks $azlks -6.28 6.28 1 rmg.cm
#xv -exp -2 ras/pres0_???.bmp &     # several layers show ambiguity errors (other image viewers can also be used)
# bash ../mymontage.sh "ras/pres0_???.bmp"

# we try to correct the unwrapping errors by rewrapping followed by spatial filtering and unwrapping
# the filtering and spatial unwrapping is done in map geometry
unw_to_cpx_pt pt pmask0 pres0 - pres0.cpx
spf_pt pt_geo pmask0 ../DEM/EQA.dem_par pres0.cpx pres0.cpx.spf_geo - 0 15 0
mcf_pt pt_geo pmask0 pres0.cpx.spf_geo - - - pres0.cpx.unw - - $ref_point 0 - - ../DEM/EQA.dem_par

# check unwrapped phases
ras_data_pt pt pmask0 pres0.cpx.unw 1 $num_row ave.rmli.bmp ras/pres0.cpx.unw 2 $rlks $azlks -6.28 6.28 1 rmg.cm
#xv -exp -2 ras/pres0.cpx.unw_???.bmp &
# bash ../mymontage.sh "ras/pres0.cpx.unw_???.bmp"

# --> it looks mostly OK except for a few smaller areas

# calculate height-dependent atmospheric phase (hoping that the local ambiguity errors will not change the result too much)
atm_mod_pt pt pmask0 pres0.cpx.unw pdem_combined patm_mod0

# having now this height-dependent atmospheric phase available
# (for all elements) we subtract if from pdiff and redo the
# regression with multi_def_pt and the subsequent rewrapping filtering and unwrapping of the residual phases

sub_phase_pt pt - pdiff - patm_mod0 pdiff0 1 0

# replace reference point values with spatially filtered value (to reduce noise)
spf_pt pt_geo pmask_single ../DEM/EQA.dem_par pdiff0 pdiff0a - 0 5 0 - $ref_point 0

# run multi_def_pt using model 1 to only estimate a height correction, assuming no deformation
# (assuming there are not deformations is acceptable as the intervals considered are short,
# nevertheless for really fast deformation with cm/month rates this can be a limitation and will result in spatial gaps)
# we use high thresholds to keep as many points as possible
multi_def_pt pt - pSLC_par - itab pbase 0 pdiff0a 1 $ref_point pres1 pdh1 - punw1 psigma1 pmask1 200. -0.01 0.01 250 1.5 1.2 1 0 1
# solution found for about 153000 elements

# visualize / check this solution
#pdisdt_pwr24 pt pmask1 ${ref_date}.rslc.par pdh1 1 ${ref_date}.rmli.par ave.rmli 100. 2
#pdisdt_pwr24 pt pmask1 ${ref_date}.rslc.par psigma1 1 ${ref_date}.rmli.par ave.rmli 1.5. 2
# -->
# height correction up to < -100m (related to glacier melting) square patterns visible, there are probably phase unwrapping errors

# visualize residuals
ras_data_pt pt pmask1 pres1 1 $num_row ave.rmli.bmp ras/pres1 2 $rlks $azlks -6.28 6.28 1 rmg.cm
#xv -exp -2 ras/pres1_???.bmp &     # several layers show ambiguity errors
# bash ../mymontage.sh "ras/pres1_???.bmp"

# we try to correct the unwrapping errors by rewrapping followed by spatial filtering and unwrapping
# the filtering and spatial unwrapping is done in map geometry
unw_to_cpx_pt pt pmask1 pres1 - pres1.cpx
spf_pt pt_geo pmask1 ../DEM/EQA.dem_par pres1.cpx pres1.cpx.spf_geo - 0 50 0
mcf_pt pt_geo pmask1 pres1.cpx.spf_geo - - - pres1.cpx.unw - - $ref_point 0 - - ../DEM/EQA.dem_par

# check unwrapped phases (this time in map geometry)
ras_data_pt pt_geo pmask1 pres1.cpx.unw 1 $num_row ../DEM/EQA.ave.rmli.bmp ras/pres1.cpx.unw 2 1 1 -6.28 6.28 1 rmg.cm 3
#xv -exp -4 ras/pres1.cpx.unw_???.bmp &
# bash ../mymontage.sh "ras/pres1.cpx.unw_???.bmp"

# --> it looks mostly OK except for a few smaller areas

# As this phase term represents the atmospheric phase we apply a spatial filtering to it (as we expect this term to be spatially low frequency) with a larger filter size and expand it to all points in the list.
# The filtering is done in the map geometry. One pixel correcponds to about 10m, so to be at about 1km spatial scale we use a radius of 50 pixels in this very rugged terrain we use a rather smaller window than in flat terrain).
rm -f ptmp1 ptmp2
spf_pt pt_geo pmask1 ../DEM/EQA.dem_par pres1.cpx.unw ptmp1 - 2 50 1
expand_data_inpaint_pt pt_geo pmask1 ../DEM/EQA.dem_par ptmp1 pt_geo - patm1 - 0 10 4 - 0

# we display the atmospheric phase patm1 (after patm_mod0 was subtracted)
ras_data_pt pt_geo - patm1 1 $num_row ../DEM/EQA.ave.rmli.bmp ras/patm1 2 1 1 -6.28 6.28 1 rmg.cm 3
#xv -exp -4 ras/patm1_???.bmp &
# bash ../mymontage.sh "ras/patm1_???.bmp"

# we subtract the estimated atmospheric path delays (patm_mod0 and patm1)
sub_phase_pt pt - pdiff - patm_mod0 pdiff0 1 0
sub_phase_pt pt - pdiff0 - patm1 pdiff1 1 0

# display pdiff1
ras_data_pt pt_combined - pdiff1 1 $num_row ave.rmli.bmp ras/pdiff1 0 $rlks $azlks - - 1
#xv -exp -2 ras/pdiff1_???.bmp &
# bash ../mymontage.sh "ras/pdiff1_???.bmp"

# --> overall the differential interferograms are now quite flat (but at somewhat different average phase levels)

cd ../
