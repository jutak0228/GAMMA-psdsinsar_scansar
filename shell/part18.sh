#!/bin/bash

# Test step 2: import (expand) previous result to new point list

work_dir="$1"
ref_date="$2"
ref_point="$3"
rlks="$4"
azlks="$5"

cd ${work_dir}/ipta_test

# copy point list and some other files to ipta_test directory
/bin/cp ../input_files_all_single_look_test/previous_ipta_result/${ref_date}.rslc.par .
/bin/cp ../input_files_all_single_look_test/previous_ipta_result/${ref_date}.rmli.par .
/bin/cp ../input_files_all_single_look_test/previous_ipta_result/ave.rmli .
/bin/cp ../input_files_all_single_look_test/previous_ipta_result/ave.rmli.bmp .
/bin/cp ../input_files_all_single_look_test/previous_ipta_result/SLC_tab   .
/bin/cp ../input_files_all_single_look_test/previous_ipta_result/itab   .
/bin/cp ../input_files_all_single_look_test/previous_ipta_result/pbase   .
/bin/cp ../input_files_all_single_look_test/DEM/EQA.ave.rmli.bmp .

# generate directory for rasterfiles
if [ -e ras ];then rm -r ras; fi
mkdir -p ras

# define (uncorrected) DEM heights for large list
# assign heights from DEM
data2pt ../DEM/${ref_date}.hgt ${ref_date}.rmli.par pt ${ref_date}.rslc.par pdem 1 2
# --> pdem

# replace DEM heights with corrected heights where available
# determine these corrections for the small list
lin_comb_pt ../input_files_all_single_look_test/previous_ipta_result/pt - ../input_files_all_single_look_test/previous_ipta_result/phgt4 - ../input_files_all_single_look_test/previous_ipta_result/pdem_combined - pdh1_previous - 0.0 1. -1. 2 0
#pdisdt_pwr24 ../input_files_all_single_look_test/previous_ipta_result/pt  - 20190809.rslc.par pdh1_previous 1 20190809.rmli.par ave.rmli 100. 5
# "resample" these corrections (pdh1) to the large list
expand_data_pt ../input_files_all_single_look_test/previous_ipta_result/pt - ${ref_date}.rslc.par pdh1_previous pt - pdh1 1 2 1 0 1
# apply the corrections for large list
lin_comb_pt pt - pdh1 1 pdem 1 phgt1 1 0.0 1. 1. 2 1
# display combined heights phgt1
#pdisdt_pwr24 pt  - 20190809.rslc.par phgt1   1 20190809.rmli.par ave.rmli 100. 3
# remove pdh1 and pdh1_previous
/bin/rm pdh1 pdh1_previous
# --> phgt1

# determine reference point number in the new list
# same point as in previous list (but having a different number)
# previous reference point number is 41061
prt_pt ../input_files_all_single_look_test/previous_ipta_result/pt - ../input_files_all_single_look_test/previous_ipta_result/phgt4 ${ref_point} 1 2 prt_pt.txt 1 1
#        1    41061   3127    761  1.99458459e+03
rg_ref=`grep "1" prt_pt.txt | awk -F" " '{print $3}'`
az_ref=`grep "1" prt_pt.txt | awk -F" " '{print $4}'`

prox_prt pt - phgt1 $rg_ref $az_ref 1 1 1 2 prox_prt.txt 1
#        1 3796486   3127    761  1.99458e+03
# --> new reference point number: 3796486
ref_point_rev=`grep "1" prox_prt.txt | awk -F" " '{print $2}'`

# determine pixel coordinates im map geoemtry
pt2geo pt - ${ref_date}.rslc.par - phgt1 ../DEM/EQA.dem_par ../DEM/${ref_date}.diff_par $rlks $azlks pt_geo plat_lon

# expand patm from previous list to the new large list:
expand_data_inpaint_pt ../input_files_all_single_look_test/previous_ipta_result/pt_geo ../input_files_all_single_look_test/previous_ipta_result/pmask_070A ../DEM/EQA.dem_par ../input_files_all_single_look_test/previous_ipta_result/patm pt_geo - patm - 0 10 4 - 0
# and visualize it
num_row=`cat ../int/bperp_file.txt | wc -l`
echo "number of rows in ../int/bperp_file.txt is ... $num_row"

ras_data_pt pt - patm 1 $num_row ave.rmli.bmp ras/patm 2 $rlks $azlks -6.28 6.28 1 rmg.cm 0 2
#xv -exp -2 ras/patm_???.bmp &
bash ../mymontage.sh "ras/patm_???.bmp"

# expand hydrostatic component of atmopsheric path delay (patm_mod) to the new large list (resample values and determine values for other
# points using the linear model (atm_mod_pt):
expand_data_pt ../input_files_all_single_look_test/previous_ipta_result/pt ../input_files_all_single_look_test/previous_ipta_result/pmask_070A ${ref_date}.rslc.par ../input_files_all_single_look_test/previous_ipta_result/patm_mod pt - patm_modtmp - 2 1 0 1
# determine mask pmask1 for values with value from small list solution
lin_comb_pt pt - patm_modtmp 1 patm_modtmp 1 patm_modtmp1 1 1000.0 1. 0. 2 0
/bin/rm pmask1
thres_msk_pt pt pmask1 patm_modtmp1 1 900. 1101.
# determine patm_mod based on small list solution
atm_mod_pt pt pmask1 patm_modtmp phgt1 patm_mod -
# determine values for interferometric pairs

