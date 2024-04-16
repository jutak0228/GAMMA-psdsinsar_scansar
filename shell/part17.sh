#!/bin/bash

# Test step 1: determine new point list (using mkgrid)

work_dir="$1"
ref_date="$2"
rlks="$3"
azlks="$4"

rlks_r=$((rlks*3))
azlks_r=$((azlks*3))

# for the demo we use the working directory ipta_test
if [ -e ipta_test ];then rm -r ipta_test; fi
mkdir ipta_test
cd ipta_test

/bin/cp ../input_files_all_single_look_test/previous_ipta_result/${ref_date}.rslc.par .
/bin/cp ../input_files_all_single_look_test/previous_ipta_result/${ref_date}.rmli.par .
/bin/cp ../input_files_all_single_look_test/previous_ipta_result/${ref_date}.rmli .

# generate pt list to convert every single-look (range oversampled) RSLC pixel
ss_width=`grep "range_samples" ${ref_date}.rslc.par | awk -F":" '{print $2}'`
ss_height=`grep "azimuth_lines" ${ref_date}.rslc.par | awk -F":" '{print $2}'`
mkgrid pt_tmp ${ss_width} ${ss_height} 1 1 13 1            # --> 8100 x 1500 = 12'150'000 points

# mask layover and shadow, as well as areas with very low coherence
msk_pt pt_tmp - ../DEM/${ref_date}.ls_map_rdc_mask.bmp pt_tmp_2 pmask3_1 $rlks $azlks # reduce candidates to 10850994
msk_pt pt_tmp_2 - ../input_files_all_single_look_test/ave.cc_mask.bmp pt pmask3_2 $rlks_r $azlks_r  # reduce candidates to  8722355
rm -f pt_tmp_1 pt_tmp_2 pmask_1 pmask3_2

#cp pt pt_8722355
cp pt pt_ls

data2pt ../DEM/${ref_date}.hgt ${ref_date}.rmli.par pt ../rslc/${ref_date}.rslc.par phgt3 1 2
#pdisdt_pwr24 pt - ../rslc/20190809.rslc.par phgt3 1 20190809.rmli.par 20190809.rmli 200. 0

# The next steps are now:
#      - expand previous solution to large list
#      - iterate solution for large list
#      - quality control
#      - generate solution files

