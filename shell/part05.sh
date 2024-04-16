#!/bin/bash

# Part 5: Compute the average image

work_dir="$1"
ref_date="$2"
rlks="$3"
azlks="$4"

if [ -e ave ];then rm -r ave; fi
mkdir -p ave
cd ave

# copy dates
cp ../rslc/dates .

# multilook SLC images, from here we use 9 looks in range on the oversampled data
while read line; do echo "$line $rlks $azlks" >> dates_mli; done < dates
run_all.pl dates_mli 'multi_look ../rslc/$1.rslc ../rslc/$1.rslc.par $1.rmli $1.rmli.par $2 $3'
rm -f dates_mli

# generate BMP images
mli_width=`grep "range_sample" ${ref_date}.rmli.par | awk -F":" '{print $2}'`
# while read line; do echo "$line $mli_width" >> dates_mli; done < dates
# run_all.pl dates_mli 'raspwr $1.rmli $2'

# generate list of MLI images
make_tab dates MLI_list '$1.rmli'

# compute average image
ave_image MLI_list $mli_width ave.rmli

# visualize average image
raspwr ave.rmli $mli_width 1 0 1 1 1. .35 gray.cm ave.rmli.bmp
# ras_dB ave.rmli 900 1 0 1 1 -21. -2.0 0. 1 ave.rmli.dB.bmp
#dispwr ave.rmli $mli_width

cd ../