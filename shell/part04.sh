#!/bin/bash

# Part 4: Deramp the data, oversample the data in range direction, and crop the area of interest

work_dir="$1"
ref_date="$2"
rlks="$3"
azlks="$4"

if [ -e rslc ];then rm -r rslc; fi

cd rslc_prep

mkdir ../rslc
cp dates ../rslc/dates

# <revised part>

# deramp all scenes based on the reference scene, this is required for the point selection using "mk_sp_all" / "sp_stat"
# Notice that ScanSAR_deramp_2nd.py checks if the deramping phase ramp for the reference already exists;
# if not the reference it is generated.
# ScanSAR_deramp_2nd.py also generates the mosaic SLC
while read line; do echo "$line $ref_date $rlks $azlks" >> dates_rev; done < dates
run_all.pl dates_rev 'ScanSAR_deramp_2nd.py $1.RSLC_tab $1 $2.RSLC_tab $3 $4 1'

# <old version>

# # deramp all scenes based on the reference scene, this is required for the point selection using "mk_sp_all" / "sp_stat"
# # Notice that S1_deramp_TOPS_slave checks if the deramping phase ramp for the reference already exists;
# # if not the reference it is generated.
# # S1_deramp_TOPS_slave also generates the mosaic SLC
# while read line; do echo "$line $ref_date $rlks $azlks" >> dates_rev; done < dates
# run_all.pl dates_rev 'S1_deramp_TOPS_slave $1.vv.RSLC_tab $1 $2.vv.RSLC_tab $3 $4 1'
# rm -f dates_rev

# crop area of interest (including some margin)
mli_width=`grep "range_sample" ${ref_date}.rmli.par | awk -F":" '{print $2}'`
raspwr ${ref_date}.rmli ${mli_width} - - - - - - - ${ref_date}.rmli.ras 
disras ${ref_date}.rmli.ras
echo -n "Input the coordinates of top-left and bottom_right for subset area to trim the multi-looked SAR image."
echo -n Input coordinate must be of multi_looked SAR image.
echo -n They are converted into single-look SAR coordinate automatically.
echo ===input example===
echo "1 500 1000 2000"
echo "In the above case, the subset area is defined from (1, 500) to (1000, 2000) in multi-looked SAR image."
read ml_subset_params
rg1_ml=`echo ${ml_subset_params} | awk -F" " '{print $1}'`
az1_ml=`echo ${ml_subset_params} | awk -F" " '{print $2}'`
rg2_ml=`echo ${ml_subset_params} | awk -F" " '{print $3}'`
az2_ml=`echo ${ml_subset_params} | awk -F" " '{print $4}'`

#rg_off=$(((rg1_ml-1)*rlks+1))
#ss_width=$(((rg2_ml-rg1_ml+1)*rlks))
#az_off=$(((az1_ml-1)*azlks+1))
#ss_height=$(((az2_ml-az1_ml+1)*azlks))

rg_off=$((rg1_ml*rlks))
ss_width=$(((rg2_ml-rg1_ml)*rlks))
az_off=$((az1_ml*azlks))
ss_height=$(((az2_ml-az1_ml)*azlks))

echo 'subset_params="'`echo ${rg_off} ${ss_width} ${az_off} ${ss_height}`'"' >> subset_param.txt
source subset_param.txt

while read line; do echo "$line $subset_params" >> dates_copy; done < dates
run_all.pl dates_copy 'SLC_copy $1.rslc.deramp $1.rslc.deramp.par $1.rslc.deramp.crop $1.rslc.deramp.crop.par - - $2 $3 $4 $5'
rm -f dates_copy

# oversample by factor 2 in range
run_all.pl dates 'SLC_ovr $1.rslc.deramp.crop $1.rslc.deramp.crop.par $1.rslc.deramp.crop.ovr $1.rslc.deramp.crop.ovr.par 2.0 1.0 1 9'

# remove margin (15 pix of MLI) and copy data

rg_off=$((15*rlks))
ss_width=$(((rg2_ml-rg1_ml-30)*rlks*2)) # because of the factor 2.0 is from oversamled value in range
az_off=$((15*azlks))
ss_height=$(((az2_ml-az1_ml-30)*azlks*1)) # because of the factor 1.0 is from oversampled value in azimuth

echo 'margin_params="'`echo ${rg_off} ${ss_width} ${az_off} ${ss_height}`'"' >> margin_param.txt
source margin_param.txt

while read line; do echo "$line $margin_params" >> dates_margin; done < dates
run_all.pl dates_margin 'SLC_copy $1.rslc.deramp.crop.ovr $1.rslc.deramp.crop.ovr.par ../rslc/$1.rslc ../rslc/$1.rslc.par - - $2 $3 $4 $5'
rm -f dates_margin

# remove intermediate data
#run_all.pl dates 'rm -f $1.slc $1.slc.par $1.rslc $1.rslc.par $1_rslc $1_rslc.par $1_rslc.tops_par $1.vv.RSLC_tab'
rm -f *.lt *.sim_unw *.rslc.deramp.crop *.rslc.deramp.crop.par *.rslc.deramp.crop.ovr *.rslc.deramp.crop.ovr.par

cd ../