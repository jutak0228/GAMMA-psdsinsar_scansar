#!/bin/bash

# Part 10: Reference point selection

work_dir="$1"
ref_date="$2"
rlks="$3"
azlks="$4"

cd ipta

#pdisdt_pwr24 pt_combined pmask_single ${ref_date}.rslc.par pdem_combined 1 ${ref_date}.rmli.par ave.rmli 200.0 1
# --> determine suited approximate location (spatially near center, stable, high point density)

# use the spectral coherence to select reference
data2pt sp_dir/ave.sp_cc ${ref_date}.rslc.par pt_combined ${ref_date}.rslc.par psp_cc 1 2
pdisdt_pwr pt_combined - ${ref_date}.rslc.par psp_cc 1 ${ref_date}.rmli.par ave.rmli 0.3 0.5 0 cc.cm

# determine reference point location (spatially near center, stable, high point density)
mli_width=`grep "range_sample" ${ref_date}.rmli.par | awk -F":" '{print $2}'`
# raspwr ${ref_date}.rmli ${mli_width} - - - - - - - ${ref_date}.rmli.ras 
# disras ${ref_date}.rmli.ras
echo -n "Input the point to determine the reference point."
echo ===input example===
echo "example below..." 
echo "347 761"
echo "Please enter the reference point..."
read ml_subset_params
rg_ml=`echo ${ml_subset_params} | awk -F" " '{print $1}'`
az_ml=`echo ${ml_subset_params} | awk -F" " '{print $2}'`

# 347 761 -> 9 looks in range -> 3123 761
rg_ref=$((rg_ml*rlks))
az_ref=$((az_ml*azlks))

echo 'ref_point="'`echo ${rg_ref} ${az_ref}`'"' >> ref_point.txt
source ref_point.txt

rlks_tmp=$((rlks*6))
azlks_tmp=$((azlks*6))
prox_prt pt_combined pmask_single psp_cc $ref_point $rlks_tmp $azlks_tmp 50 2 - 1 # <revised version using spectral coherence>
# prox_prt pt_combined pmask_single pdem_combined $ref_point $rlks_tmp $azlks_tmp 50 2 - 1 # <old version>

#      1  40921   3125    761  4.56680e-01
#      1  40922   3126    761  6.69393e-01
#      1  40973   3126    762  4.53658e-01
#      1  40923   3127    761  6.95940e-01
#      1  41096   3123    765  4.41823e-01
#      1  40974   3127    762  4.58192e-01
#      1  41097   3124    765  5.23804e-01
#      1  41098   3125    765  4.43823e-01
#      1  40920   3118    761  4.45875e-01
#      1  40924   3128    761  5.03552e-01
#      1  40871   3118    760  4.72276e-01
#      ...

# --> reference point: nr. 40923 (in pt_combined)

cd ../

