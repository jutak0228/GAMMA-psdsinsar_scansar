#!/bin/bash

# Part 12b: Update height corrections and atmospheric phases using multi-reference stack (using def_mod_pt)

work_dir="$1"
ref_date="$2"
rlks="$3"
azlks="$4"
ref_point="$5"

cd ipta

num_row=`cat ../int/bperp_file.txt | wc -l`
echo "number of rows in ../int/bperp_file.txt is ... $num_row"

# replace reference point values with spatially filtered values (to reduce noise)
spf_pt pt_geo pmask_single ../DEM/EQA.dem_par pdiff2 pdiff2a - 0 5 0 - $ref_point 0

# We do one more iteration to determine a height correction
# and atmospheric phase update
def_mod_pt pt - pSLC_par - itab pbase 0 pdiff2a 1 $ref_point pres3 pdh3 pddef3 punw3 psigma3 pmask3 100. -0.01 0.01 1.3 1 pdh_err3
# solution found for about 141000 elements

#pdisdt_pwr24 pt pmask3 ${ref_date}.rslc.par pdh3 1 ${ref_date}.rmli.par ave.rmli 100. 3
# the overall spatially low frequency correction previously visible at > 10m level
# has disappeared; so we can directly use the correction to update the heights
#pdisdt_pwr24 pt pmask3 ${ref_date}.rslc.par pdh_err3 1 ${ref_date}.rmli.par ave.rmli 10. 3
#pdisdt_pwr24 pt pmask3 ${ref_date}.rslc.par psigma3 1 ${ref_date}.rmli.par ave.rmli 1.5 3

ras_data_pt pt pmask3 pres3 1 $num_row ave.rmli.bmp ras/pres3 2 $rlks $azlks -6.28 6.28 1 rmg.cm
#xv ras/pres3_???.bmp &
# bash ../mymontage.sh "ras/pres3_???.bmp"

# --> unwrapping looks mostly correct

# we try to avoid unwrapping errors by rewrapping followed by spatial filtering and unwrapping
# the filtering and spatial unwrapping is done in map geometry
unw_to_cpx_pt pt pmask3 pres3 - pres3.cpx
spf_pt pt_geo pmask3 ../DEM/EQA.dem_par pres3.cpx pres3.cpx.spf_geo - 0 50 1
mcf_pt pt_geo pmask3 pres3.cpx.spf_geo - - - pres3.cpx.unw - - $ref_point 0 - - ../DEM/EQA.dem_par

# check unwrapped phases
ras_data_pt pt_geo pmask3 pres3.cpx.unw 1 $num_row ../DEM/EQA.ave.rmli.bmp ras/pres3.cpx.unw 2 1 1 -6.28 6.28 1 rmg.cm 3
#xv -exp -4 ras/pres3.cpx.unw_???.bmp &
# bash ../mymontage.sh "ras/pres3.cpx.unw_???.bmp"

# --> it looks OK for all layers
# --> Hence we accept this solution

# we add it to the patm2, filter and expand it, to get the update atmopsheric phase patm3
rm -f patm3 ptmp2 ptmp1
lin_comb_pt pt pmask3 patm2 - pres3.cpx.unw - ptmp2 - 0.0 1. 1. 2 0
spf_pt pt_geo pmask3 ../DEM/EQA.dem_par ptmp2 ptmp1 - 2 15 1
expand_data_inpaint_pt pt_geo pmask3 ../DEM/EQA.dem_par ptmp1 pt_geo - patm3 - 0 10 4 - 0

# we display the atmospheric phase patm3 (after patm_mod0 was subtracted)
ras_data_pt pt_geo - patm3 1 $num_row ../DEM/EQA.ave.rmli.bmp ras/patm3 2 1 1 -6.28 6.28 1 rmg.cm 3
#xv -exp -4 ras/patm3_???.bmp &
# bash ../mymontage.sh "ras/patm3_???.bmp"

# part12b_2.sh

# echo "Please check each layer in image list [patm3_.all.bmp]...
# and when you find unwrapping errors in the list, you should make a new list (list12b_tmp) as below
# 39
# 61
# ..."

# width=`grep "width" ../DEM/EQA.dem_par | awk -F":" '{print $2}'`

# # Assuming that the visualization reveals an unwrapping error (ambiguity error)
# # in one or several specific layers we could try to manually correct it
# # We correct those by manually adding or subtracting 2PI using LAT tools

# cp patm3 patm3.uncorrected

# # correct layers
# rm -f list12b_poly list_12b
# ras_data_pt pt_geo - patm3 1 $num_row ../DEM/EQA.ave.rmli.bmp ras/patm3 2 1 1 -6.28 6.28 1 rmg.cm 3
# while read line; do printf "%03d\n" ${line} >> list12b_poly; done < list12b_tmp
# while read line; do echo "$line $width" >> list12b; done < list12b_poly
# rm -f list12b_tmp list12b_poly

# run_all list12b 'polyras ras/patm3_$1.bmp > poly$1' # write areas where unwrapping errors are occured.
# #run_all list12b 'pdisdt_pwr24 pt pmask3 $3.rslc.par patm3 $1 $3.rmli.par ave.rmli 12.6 3' 
# # --> 2PI has to be added for polyXX area
# run_all list12b 'poly_math ../DEM/EQA.ave.rmli EQA.phase_correction $2 poly$1 - 1 6.28 0.0'
# # disdt_pwr EQA.phase_correction ../DEM/EQA.ave.rmli $width 1 1 0 12.6
# d2pt EQA.phase_correction $width pt_geo 1 1 pEQA.phase_correction 1 2
# # pdisdt_pwr24 pt - ${ref_date}.rslc.par pEQA.phase_correction 1 ${ref_date}.rmli.par ave.rmli 12.6. 3
# run_all list12b 'lin_comb_pt pt - patm3.uncorrected $1 pEQA.phase_correction 1 patm3.tmp $1 0.0 1. 1. 2 1' 
# run_all list12b 'spf_pt pt_geo pmask3 ../DEM/EQA.dem_par patm3.tmp patm3 $1 2 25 0'
# /bin/rm  ras/patm3_???.bmp
# run_all list12b 'ras_data_pt pt_geo - patm3 $1 1 ../DEM/EQA.ave.rmli.bmp ras/patm3 2 1 1 -9.42 9.42 1 rmg.cm 3'
# # xv -exp -4 ras/patm3_???.bmp &
# bash ../mymontage.sh "ras/patm3_???.bmp"

# part12b_3.sh

# update heights
#pdisdt_pwr24 pt pmask3 ${ref_date}.rslc.par pdh3 1 ${ref_date}.rmli.par ave.rmli 100. 3

lin_comb_pt pt - phgt2 1 pdh3 1 phgt3 - 0.0 1. 1. 2 1
#pdisdt_pwr24 pt - ${ref_date}.rslc.par phgt3 1 ${ref_date}.rmli.par ave.rmli 200. 3

# simulate the phase corresponding to the total height correction (pdh3.total)
# pdh3.sim_unw; then subtract it from the differential interferograms
lin_comb_pt pt - phgt3 1 pdem_combined 1 pdh3.total - 0.0000001 1. -1. 2 1
phase_sim_pt pt - pSLC_par - itab - pbase pdh3.total pdh3.sim_unw - 2 0

# we subtract the topo phase corrections as well as the estimated atmospheric path delays (patm_mod0 and patm3)
sub_phase_pt pt - pdiff - pdh3.sim_unw pdiff.0 1 0
sub_phase_pt pt - pdiff.0 - patm_mod0 pdiff.1 1 0
sub_phase_pt pt - pdiff.1 - patm3 pdiff3 1 0

# display pdiff3
ras_data_pt pt_combined - pdiff3 1 $num_row ave.rmli.bmp ras/pdiff3 0 $rlks $azlks - - 1
#xv -exp -2 ras/pdiff3_???.bmp &
# bash ../mymontage.sh "ras/pdiff3_???.bmp"

# --> the differential interferograms are quite flat (at somewhat different average phase levels). Some deviations are observed in the Moosfluh landslide area, possibly deformation phase even over these short intervals considered
