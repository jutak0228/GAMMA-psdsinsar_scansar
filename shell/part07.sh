#!/bin/bash
############################################################################################

# Parts 7 to 10 describe the generation of the combined multi-reference stack that contains
# single-pixel & multi-look differential interferometric phases

############################################################################################

# Part 7: Generate multi-look differential interferometric phases and extract these to vector data format

work_dir="$1"
ref_date="$2"
rlks="$3"
azlks="$4"
delta_t_max="$5"
delta_n_max="$6"
cc_thres="$7"

# multi-looking to use: 27 range looks x 3 azimuth looks
# pairs to consider: each scene with the 3 subsequent scenes (--> "triple redundance")

# determine list of pairs to consider
if [ -e int ]; then rm -r int; fi
mkdir int
cd int
cp ../rslc/dates .    # text file containing acquisition dates
make_tab dates SLC_tab '../rslc/$1.rslc ../rslc/$1.rslc.par'
base_calc SLC_tab ../rslc/${ref_date}.rslc.par bperp_file.txt itab 1 1 - - - $delta_t_max $delta_n_max

num_row=`cat bperp_file.txt | wc -l`
echo "number of rows in bperp_file.txt is ... $num_row"

# The baselines (bperp) are between -140m and + 163m. So the orbital tube is very narrow for S1.

# prepare height reference in 27 x 3 look geometry
# resampled factor is 3 and we need set range and azimuth looks with multiplied... 
create_offset ../DEM/${ref_date}.rmli.par ../DEM/${ref_date}.rmli.par ${ref_date}.off 1 1 1 0
multi_real ../DEM/${ref_date}.hgt ${ref_date}.off ${ref_date}.hgt3 ${ref_date}.off3 3 3
multi_real ../DEM/ave.rmli ${ref_date}.off ave.rmli3 ${ref_date}.off3 3 3
rlks_r=$((rlks*3))
azlks_r=$((azlks*3))
#dishgt 20190809.hgt3 ave.rmli3 300   # the width of these data files is 300 (see 20190809.off3)

mli_width=`cat ${ref_date}.off3 | grep "interferogram_width" | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9\.]//g"`
mli_height=`cat ${ref_date}.off3 | grep "interferogram_azimuth_lines"| awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9\.]//g"`

# calculate differential interferograms (run_all is used to run a command for each line of an ascii file)

# create offset parameter files for all selected multi-reference pairs
run_all.pl bperp_file.txt 'echo $1 $2 $3 >> bperp_file_clip.txt' 
while read line; do echo "$line $ref_date $mli_width $mli_height $rlks_r $azlks_r" >> bperp_file_ref.txt; done < bperp_file_clip.txt
#rm -f bperp_file_clip.txt
run_all.pl bperp_file_ref.txt 'create_offset ../rslc/$2.rslc.par ../rslc/$3.rslc.par $2_$3.off 1 $7 $8 0'

# run phase_sim_orb for all 66 selected multi-reference pairs
run_all.pl bperp_file_ref.txt 'phase_sim_orb ../rslc/$2.rslc.par ../rslc/$3.rslc.par $2_$3.off $4.hgt3 $2_$3.sim_unw ../rslc/$4.rslc.par - - 1 1'

# generate differential interferogram for all 66 selected multi-reference pairs
run_all.pl bperp_file_ref.txt 'SLC_diff_intf ../rslc/$2.rslc ../rslc/$3.rslc ../rslc/$2.rslc.par ../rslc/$3.rslc.par $2_$3.off $2_$3.sim_unw $2_$3.diff $7 $8 0 0'

# multilook SLC images
while read line; do echo "$line $rlks_r $azlks_r" >> dates_rev; done < dates
run_all.pl dates_rev 'multi_look ../rslc/$1.rslc ../rslc/$1.rslc.par $1.rmli $1.rmli.par $2 $3'

# calculate coherence
run_all.pl bperp_file_ref.txt 'cc_ad $2_$3.diff $2.rmli $3.rmli - - $2_$3.cc $5'

# calculate average of coherence and create mask
make_tab bperp_file.txt CC_list '$2_$3.cc'
ave_image CC_list $mli_width ave.cc
#discc ave.cc - $mli_width
#disdt_pwr ave.cc ${ref_date}.rmli $mli_width - - 0 1 0 cc.cm
rascc_mask ave.cc ${ref_date}.rmli $mli_width 1 1 0 1 1 $cc_thres 0.0 0.0 1.0 1. .35 1 ave.cc_mask.bmp
# --> ave.cc_mask.bmp   # glacier areas, layover and shadow areas, water surfaces and forests are below the threshold

# generate bmp rasterfiles for all the 66 differential interferograms
run_all.pl bperp_file_ref.txt 'rasmph_pwr $2_$3.diff ave.rmli3 $5 1 0 1 1 rmg.cm $2_$3.diff.bmp 1 .35 24'

# generate pt list to convert multi-look cpx diff values to vector data format as used in IPTA
mkgrid pt3_tmp_1 $mli_width $mli_height $rlks_r $azlks_r 13 1            # --> 300 x 500 = 150'000 points

# mask layover and shadow, as well as areas with very low coherence
msk_pt pt3_tmp_1 - ../DEM/${ref_date}.ls_map_rdc_mask.bmp pt3_tmp_2 pmask3_1 $rlks $azlks # reduce candidates to 134'325
msk_pt pt3_tmp_2 - ave.cc_mask.bmp pt3 pmask3_2 $rlks_r $azlks_r                          # reduce candidates to 107'954
rm -f pt3_tmp_1 pt3_tmp_2 pmask3_1 pmask3_2
# --> pt3 includes 107954 points

# read $2_$3.diff values into vector data stack pdiff3
multi_look ../rslc/${ref_date}.rslc ../rslc/${ref_date}.rslc.par ${ref_date}.rmli3 ${ref_date}.rmli3.par $rlks_r $azlks_r
run_all.pl bperp_file_ref.txt 'data2pt $2_$3.diff $4.rmli3.par pt3 ../rslc/$4.rslc.par pdiff3 $1 0'

#pdismph_pwr24 pt3 - ../rslc/${ref_date}.rslc.par pdiff3 21 ${ref_date}.rmli3.par ave.rmli3 0

# import height data into phgt3
data2pt ${ref_date}.hgt3 ${ref_date}.rmli3.par pt3 ../rslc/${ref_date}.rslc.par phgt3 1 2
#pdisdt_pwr24 pt3 - ../rslc/${ref_date}.rslc.par phgt3 1 ${ref_date}.rmli3.par ${ref_date}.rmli3 200. 0

# --> point list with related multi-look cpx diff phases and heights: pt3, pdiff3, phgt3
#     compatible with corresponding single pixel diff phases to be extracted

ras_pt pt3 - ../DEM/ave.rmli.bmp pt3.bmp $rlks $azlks 255 255 0 1
#disras pt3.bmp

