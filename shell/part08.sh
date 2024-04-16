#!/bin/bash

# Part 8: Generate single-pixel (PSI) differential interferometric phases
#         in vector data format for a list of persistent scatterer candidates
#         selected using sp_stat and pwr_stat

work_dir="$1"
ref_date="$2"
rlks="$3"
azlks="$4"
th_spcc="$5"
th_msr="$6"

if [ -e ipta ];then rm -r ipta; fi
mkdir ipta
cd ipta

/bin/cp ../DEM/ave.rmli .
/bin/cp ../DEM/${ref_date}.hgt .
/bin/cp ../rslc/dates .
/bin/cp ../int/itab .
mkdir ras

num_row=`cat ../int/bperp_file.txt | wc -l`
echo "number of rows in bperp_file.txt is ... $num_row"

# generate 20190809.rmli 20190809.rmli.par (9 x 1 look for visualization of results)
/bin/cp ../rslc/${ref_date}.rslc.par .
multi_look ../rslc/${ref_date}.rslc ../rslc/${ref_date}.rslc.par ${ref_date}.rmli ${ref_date}.rmli.par $rlks $azlks

mli_width=`grep "range_samples" ${ref_date}.rmli.par | awk -F":" '{print $2}'`
ras_dB ave.rmli $mli_width 1 0 1 1 -21. -2.0 gray.cm ave.rmli.bmp 0 1
#disras ave.rmli.bmp

# Point candidates selection
# NOTE: the thresholds can be slightly adjusted to yield fewer or more points

make_tab dates SLC_tab '../rslc/$1.rslc ../rslc/$1.rslc.par'

rm -f sp_dir/ave.sp_cc sp_dir/ave.sp_msr
mk_sp_all SLC_tab sp_dir 4 4 0.0 $th_spcc 0.5 2   # data was oversampled by a factor 2 in range direction (see Part 4)

# using sp_stat results
slc_width=`grep "range_samples" ${ref_date}.rslc.par | awk -F":" '{print $2}'`
thres_im_pt sp_dir/ave.sp_cc $slc_width pt2_tmp $th_spcc 1.0 1 1

# mask layover and shadow
msk_pt pt2_tmp - ../DEM/${ref_date}.ls_map_rdc_mask.bmp pt2 pmask2 $rlks $azlks
rm -f pt2_tmp pmask2

ras_pt pt2 - ave.rmli.bmp pt2.bmp $rlks $azlks 255 255 0 3
#disras pt2.bmp 
# -->
# lower threshold in thres_im_pt: 0.42 -> 67767 points

cp pt2 pt_sp

# using pwr_stat:  (notice flag for FCOMPLEX/SCOMPLEX)
# the threshold was adjusted such that a point number of about 1/4 of the one obtained with sp_stat is obtained (with 25 scenes
# this criteria is not expected to be very reliable and therefore it is preferred not to accept too many candidates using it.
pwr_stat SLC_tab ${ref_date}.rslc.par MSR pt1_tmp $th_msr 0.5 - - - - 0 2

# mask layover and shadow
msk_pt pt1_tmp - ../DEM/${ref_date}.ls_map_rdc_mask.bmp pt1 pmask1 $rlks $azlks
rm -f pt1_tmp pmask1

ras_pt pt1 - ave.rmli.bmp pt1.bmp $rlks $azlks 255 0 0 3
#disras pt1.bmp
# -->
# mean/sigma ratio minimum threshold in pwr_stat: 2.2 -> 16123 points
cp pt1 pt_pwr

# merge 2 point lists
echo "pt1" > plist_tab
echo "pt2" >> plist_tab
merge_pt plist_tab pt 1 0 0

# total number of points in the input lists: 83890
# total number of unique locations: 75627
# writing point coordinate file: pt   number of points: 75627

mv pt pt_all
ras_pt pt_all - ave.rmli.bmp pt_all.bmp $rlks $azlks 255 0 0 3

# -->
# point list from sp_stat:  pt_67767
# point list from pwr_stat: pt_16123
# combined point list:      pt_75627

# generate point differential interferograms

# import heights
data2pt ${ref_date}.hgt ${ref_date}.rmli.par pt_all ${ref_date}.rslc.par pdem 1 2
#pdisdt_pwr24 pt_all - ${ref_date}.rslc.par pdem 1 ${ref_date}.rmli.par ave.rmli 200.0 1

# generate pSLC_par pSLC data stack
rm -f pSLC_par pSLC
SLC2pt SLC_tab pt_all - pSLC_par pSLC -

# estimate baseline from orbit state vectors (pbase.orbit)
base_orbit_pt pSLC_par itab - pbase.orbit

# generate interferogram point data stack (pint)
intf_pt pt_all - itab - pSLC pint 0   # 0 for FCOMPLEX;  1 for SCOMPLEX

# simulate unwrapped interferometric phase: orbital and terrain phase (using phase_sim_orb)
phase_sim_orb_pt pt_all - pSLC_par - itab - pdem psim_unw ${ref_date}.rslc.par -

# subtract orbital and terrain phase from pint
sub_phase_pt pt_all - pint - psim_unw pdiff 1 0

# visualize pdiff
ras_data_pt pt_all - pdiff 1 $num_row ave.rmli.bmp ras/pdiff 0 $rlks $azlks - - 1
#xv ras/pdiff_???.bmp &
# bash ../mymontage.sh "ras/pdiff_???.bmp"

# --> point list with related cpx diff phases and heights: pt_75627, pdiff, pdem

cd ../
