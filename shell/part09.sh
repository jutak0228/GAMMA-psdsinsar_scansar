#!/bin/bash

# Part 9: Combined PSI and multi-look lists and phases into one combined vector data set 
#	    and generate pmask files documenting the origin of a value (single pixel or multi-look)

work_dir="$1"
ref_date="$2"
rlks="$3"
azlks="$4"

cd ipta

# determine concatenated list and pdem for single-pixel and multi-look values
cat_pt pt_all - pdem ../int/pt3 - ../int/phgt3 pt_combined - pdem_combined 2 0
npt pt_combined     # --> 183581 points
cp pt_combined pt_psds

# generate combined pdiff (--> pdiff_combined)
cat_pt pt_all - pdiff ../int/pt3 - ../int/pdiff3 pt_combined - pdiff_combined 0 0

# determine masks for the single-pixel and multi-look elements:
# to differentiate them we use pdem for the single-pixel elements and set the heights for the multi-look elements to a large value
lin_comb_pt ../int/pt3 - ../int/phgt3 1 ../int/phgt3 1 phgt3A 1 1000000 0. 0. 2 1    # sets values in phgt3A to 1'000'000

# concatenate pdem with the modified heights for the multi-look elements
cat_pt pt_all - pdem ../int/pt3 - phgt3A pt_combined - ptmp1 2 0

# generate the masks
rm pmask_single pmask_multilook   # remove pre-existing masks
thres_msk_pt pt_combined pmask_single ptmp1 1 -100. 10000.
# --> points within mask after threshold test: 75627 (these are the single-pixel candidates)
thres_msk_pt pt_combined pmask_multilook ptmp1 1 999999. 1000001.
# --> points within mask after threshold test: 107954 (these are the multi-look locations)

# visualize pdem for single-pixel elements, multi-look elements and both together
#pdisdt_pwr24 pt_combined pmask_single ${ref_date}.rslc.par pdem_combined 1 ${ref_date}.rmli.par ave.rmli 200.0 1
# --> 75569 non-zero values
#pdisdt_pwr24 pt_combined pmask_multilook ${ref_date}.rslc.par pdem_combined 1 ${ref_date}.rmli.par ave.rmli 200.0 1
# --> 107954 non-zero values
#pdisdt_pwr24 pt_combined - ${ref_date}.rslc.par pdem_combined 1 ${ref_date}.rmli.par ave.rmli 200.0 1

# visualize record 21 of pdiff for single-pixel elements, multi-look elements and both together
#pdismph_pwr24 pt_combined pmask_single ${ref_date}.rslc.par pdiff_combined 21 ${ref_date}.rmli.par ave.rmli 1
# --> 75569 non-zero values
#pdismph_pwr24 pt_combined pmask_multilook ${ref_date}.rslc.par pdiff_combined 21 ${ref_date}.rmli.par ave.rmli 1
# --> 107954 non-zero values
#pdismph_pwr24 pt_combined - ${ref_date}.rslc.par pdiff_combined 21 ${ref_date}.rmli.par ave.rmli 1

num_row=`cat ../int/bperp_file.txt | wc -l`
echo "number of rows in ../int/bperp_file.txt is ... $num_row"

# display all combined differential interferograms
ras_data_pt pt_combined - pdiff_combined 1 $num_row ave.rmli.bmp ras/pdiff_combined 0 $rlks $azlks - - 1
#xv ras/pdiff_combined_???.bmp &
# bash ../mymontage.sh "ras/pdiff_combined_???.bmp"

cd ../
