#!/bin/bash

# Part 12a: Estimate height correction and update atmospheric phases using multi-reference stack (using def_mod_pt)
#           Note 1: For the height correction we separate a high frequency and a low frequncy part.
#                   Only the high frequncy part is considered as a "real height correction, the low
#                   frequency part is considered as an anomaly relating to atmosphere
#           Note 2: We use here a small window for the estimation of the "atmospheric phase",
#                   knowing that it will also include some deformation phase. The final interpretation
#                   of the phase will be done later, here the main objective is to
#                   get consistently (correctly) unwrapped phases.

work_dir="$1"
ref_date="$2"
rlks="$3"
azlks="$4"
ref_point="$5"

cd ipta

num_row=`cat ../int/bperp_file.txt | wc -l`
echo "number of rows in ../int/bperp_file.txt is ... $num_row"

# replace reference point values with spatially filtered value (to reduce noise)
spf_pt pt_geo pmask_single ../DEM/EQA.dem_par pdiff1 pdiff1a - 0 5 0 - $ref_point 0

# now after subtracting the atmospheric phase we should be able to use def_mod_pt with one spatial reference point
# Again we use model 1 to only estimate a height correction and to determine an update to the atmospheric phase
def_mod_pt pt - pSLC_par - itab pbase 0 pdiff1a 1 $ref_point pres2 pdh2 - punw2 psigma2 pmask2 200. -0.01 0.01 1.4 1 pdh_err2
# solution found for about 145000 elements

#pdisdt_pwr24 pt pmask2 ${ref_date}.rslc.par pdh2 1 ${ref_date}.rmli.par ave.rmli 100. 3
#pdisdt_pwr24 pt pmask2 ${ref_date}.rslc.par pdh_err2 1 ${ref_date}.rmli.par ave.rmli 10. 3
#pdisdt_pwr24 pt pmask2 ${ref_date}.rslc.par psigma2 1 ${ref_date}.rmli.par ave.rmli 1.5. 3

# the height corrections over some glacier areas are about -100m due to melting of the ice.
# For other areas the height corrections are between about -40m and + 40m. This is a very
# high value, higher than the expected DEM errors and higher than the statistical error
# indicated by def_mod_pt (pdh_err2: up to about 8m ). Our interpreatation is that
# this large height correction relates to uncompensated atmospheric phase (that is
# not random) in combination with the low phase to height sensitivity of this stack
# with short spatial baselines.

ras_data_pt pt pmask2 pres2 1 $num_row ave.rmli.bmp ras/pres2 2 $rlks $azlks -6.28 6.28 1 rmg.cm
#xv ras/pres2_???.bmp &
# bash ../mymontage.sh "ras/pres2_???.bmp"

# --> unwrapping looks mostly correct; but there may still be ambiguity errors
#     so we rewrap, filter, spatially unwrap the residual phase

# we try to avoid unwrapping errors by rewrapping followed by spatial filtering and unwrapping
# the filtering and spatial unwrapping is done in map geometry
unw_to_cpx_pt pt pmask2 pres2 - pres2.cpx
spf_pt pt_geo pmask2 ../DEM/EQA.dem_par pres2.cpx pres2.cpx.spf_geo - 0 50 1
mcf_pt pt_geo pmask2 pres2.cpx.spf_geo - - - pres2.cpx.unw - - $ref_point 0 - - ../DEM/EQA.dem_par

# check unwrapped phases
ras_data_pt pt_geo pmask2 pres2.cpx.unw 1 $num_row ../DEM/EQA.ave.rmli.bmp ras/pres2.cpx.unw 2 1 1 -6.28 6.28 1 rmg.cm 3
#xv -exp -4 ras/pres2.cpx.unw_???.bmp &
# bash ../mymontage.sh "ras/pres2.cpx.unw_???.bmp"

# --> it looks mostly OK except very few smaller areas so we accept this unwrapping solution

# part12a_2.sh

# Alternatively we could improve selected layers with
# a local ambiguity error using e.g.
# echo "8" > list1
# ...
#
# run_all list1 'spf_pt pt_geo pmask2 ../DEM/EQA.dem_par pres2.cpx pres2.cpx.spf_geo $1 0 25 1'
# run_all list1 'mcf_pt pt_geo pmask2 pres2.cpx.spf_geo $1 - - pres2.cpx.unw - - 40923 0 - - ../DEM/EQA.dem_par pdem_combined 10.0'
# /bin/rm ras/pres2.cpx.unw_???.bmp
# run_all list1 'ras_data_pt pt_geo pmask2 pres2.cpx.unw $1 1 ../DEM/EQA.ave.rmli.bmp ras/pres2.cpx.unw 2 1 1 -6.28 6.28 1 rmg.cm 3'
# xv -exp -4 ras/pres2.cpx.unw_???.bmp &

# part12a_3.sh

# after accepting the unwrapped phases as correct; 
# we add it to the patm1, filter and expand it, to get the update atmopsheric phase patm2
rm -f patm2 ptmp2 ptmp1
lin_comb_pt pt - patm1 - pres2.cpx.unw - ptmp2 - 0.0 1. 1. 2 0
spf_pt pt_geo pmask2 ../DEM/EQA.dem_par ptmp2 ptmp1 - 2 15 1
expand_data_inpaint_pt pt_geo pmask2 ../DEM/EQA.dem_par ptmp1 pt_geo - patm2 - 0 10 4 - 0

# we display the atmospheric phase patm2 (after patm_mod0 was subtracted)
ras_data_pt pt_geo - patm2 1 $num_row ../DEM/EQA.ave.rmli.bmp ras/patm2 2 1 1 -6.28 6.28 rmg.cm 3
#xv -exp -4 ras/patm2_???.bmp &
# bash ../mymontage.sh "ras/patm2_???.bmp"

# update heights; we separate a low and a high frequency part of the correction
fspf_pt pt_geo pmask2 ../DEM/EQA.dem_par pdh2 pdh2.spf - 2 150 0
#pdisdt_pwr24 pt - ${ref_date}.rslc.par pdh2.spf 1 ${ref_date}.rmli.par ave.rmli 100. 3
lin_comb_pt pt pmask2 pdh2 1 pdh2.spf 1 pdh2.hf - 0.0 1. -1. 2 0
#pdisdt_pwr24 pt - ${ref_date}.rslc.par pdh2.hf 1 ${ref_date}.rmli.par ave.rmli 100. 3
thres_msk_pt pt pmask.tmp1 pdh2.hf 1 -20. 20
#pdisdt_pwr24 pt pmask.tmp1 ${ref_date}.rslc.par pdh2.hf 1 ${ref_date}.rmli.par ave.rmli 100. 3
fspf_pt pt_geo pmask.tmp1 ../DEM/EQA.dem_par pdh2 pdh2.spf - 2 150 0 1
#pdisdt_pwr24 pt - ${ref_date}.rslc.par pdh2.spf 1 ${ref_date}.rmli.par ave.rmli 100. 3
lin_comb_pt pt pmask2 pdh2 1 pdh2.spf 1 pdh2.hf - 0.0 1. -1. 2 0
#pdisdt_pwr24 pt - ${ref_date}.rslc.par pdh2.hf 1 ${ref_date}.rmli.par ave.rmli 100. 3

# -->
# the height correction has a low frequency part pdh2.spf and a high frequency part pdh2.hf.
# We use the high frequency part to update the terrain heights (phgt2 = pdem_combined + pdh2.hf)
# We estimate the phase effect for the height correction and subtract it then from the differential interferograms.
# We shift the phase corresponding to the low frequency part into the atmospheric phase (so that we don't get this correction again in a next iteration).

lin_comb_pt pt - pdem_combined 1 pdh2.hf 1 phgt2 - 0.0 1. 1. 2 1
#pdisdt_pwr24 pt - ${ref_date}.rslc.par phgt2 1 ${ref_date}.rmli.par ave.rmli 200. 3

# simulate the phase corresponding to the height correction pdh2.hf and subtract it from the differential interferograms
phase_sim_pt pt pmask2 pSLC_par - itab - pbase pdh2.hf pdh2.hf.sim_unw - 2 0
ras_data_pt pt_geo - pdh2.hf.sim_unw 1 $num_row ../DEM/EQA.ave.rmli.bmp ras/pdh2.hf.sim_unw 2 1 1 -6.28 6.28 1 rmg.cm 3
#xv -exp -4 ras/pdh2.hf.sim_unw_???.bmp &    # the main effect is visible at the edges of the glaciers
# bash ../mymontage.sh "ras/pdh2.hf.sim_unw_???.bmp"

# simulate the phase corresponding to the low frequency part of the height correction pdh2.spf
# and add it to the patm2; this should avoid getting again the same effect in the next iteration.
phase_sim_pt pt pmask2 pSLC_par - itab - pbase pdh2.spf pdh2.spf.sim_unw - 2 0
# ras_data_pt pt_geo - pdh2.spf.sim_unw 1 $num_row ../DEM/EQA.ave.rmli.bmp ras/pdh2.spf.sim_unw 2 1 1 12.56 5 rmg.cm
ras_data_pt pt_geo - pdh2.spf.sim_unw 1 $num_row ../DEM/EQA.ave.rmli.bmp ras/pdh2.spf.sim_unw 2 1 1 -6.28 6.28 1 rmg.cm 3
#xv -exp -4 ras/pdh2.spf.sim_unw_???.bmp &
# bash ../mymontage.sh "ras/pdh2.spf.sim_unw_???.bmp"

cp patm2 patm2.0
/bin/rm ptmp1
lin_comb_pt pt pmask2 patm2 - pdh2.spf.sim_unw - ptmp1 - 0.0 1. 1. 2 0
expand_data_inpaint_pt pt_geo pmask2 ../DEM/EQA.dem_par ptmp1 pt_geo - patm2 - 0 10 4 - 0
#pdis2dt_map pt_geo - ../DEM/EQA.dem_par patm2 1 patm2 1 12.6 3.

# we display the atmospheric phase patm2 (after patm_mod0 was subtracted)
ras_data_pt pt_geo - patm2 1 $num_row ../DEM/EQA.ave.rmli.bmp ras/patm2 2 1 1 -6.28 6.28 1 rmg.cm 3
#xv -exp -4 ras/patm2_???.bmp &
# bash ../mymontage.sh "ras/patm2_???.bmp"

# we subtract the topo phase corrections as well as the estimated atmospheric path delays (patm_mod0 and patm2)
sub_phase_pt pt - pdiff - pdh2.hf.sim_unw pdiff.0 1 0
sub_phase_pt pt - pdiff.0 - patm_mod0 pdiff.1 1 0
sub_phase_pt pt - pdiff.1 - patm2 pdiff2 1 0

# display pdiff2
ras_data_pt pt_combined - pdiff2 1 $num_row ave.rmli.bmp ras/pdiff2 0 $rlks $azlks - - 1
#xv -exp -2 ras/pdiff2_???.bmp &
# bash ../mymontage.sh "ras/pdiff2_???.bmp"

# --> overall the differential interferograms are again quite flat (but at somewhat different average phase levels)

cd ../
