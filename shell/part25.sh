#!/bin/bash

# Test step 9: Generation of single-look time-series with noise and temporally filtered

work_dir="$1"
ref_date="$2"
rlks="$3"
azlks="$4"

cd ${work_dir}/ipta_test
ref_point_rev=`grep "1" prox_prt.txt | awk -F" " '{print $2}'`
num_row=`cat ../int/bperp_file.txt | wc -l`
echo "number of rows in ../int/bperp_file.txt is ... $num_row"

# phase time series: pdiff1.tsx
# mask indicating accepted pixels: pmask_final

# we apply a temporal smoothing to the time series using tpf_pt
# we include 9 values into the filter and use the linear least-squares

tpf_pt pt pmask_final pSLC_par itab_ts pdiff1.tsx pdiff1.tsx.tpf 2 70. 2 9

# we determine the noise as the deviation from the temporal smoothed solution
lin_comb_pt pt pmask_final pdiff1.tsx - pdiff1.tsx.tpf - pres5 - 0. 1. -1. 2 0

#pdisdt_pwr24 pt - ${ref_date}.rslc.par pres5 1 ${ref_date}.rmli.par ave.rmli 6.28 3
#pdisdt_pwr24 pt - ${ref_date}.rslc.par pres5 10 ${ref_date}.rmli.par ave.rmli 6.28 3

# convert phase rates and phase time series to LOS displacement rates and time series
dispmap_pt pt pmask_final pSLC_par itab_ts pdiff1.tsx phgt4 pdisp1_tsx 0
dispmap_pt pt pmask_final pSLC_par itab_ts pdiff1.tsx.tpf phgt4 pdisp1_tsx.tpf 0
dispmap_pt pt pmask_final pSLC_par itab_ts pratex phgt4 pdisp1_ratex 0

prasdt_pwr pt pmask_final ${ref_date}.rslc.par pdisp1_ratex 1 ${ref_date}.rmli.par ave.rmli -0.15 0.15 0 hls.cm pdisp1_ratex.bmp
dis_data pt pmask_final pSLC_par itab_ts 2 pdisp1_tsx pdisp1_tsx.tpf 0 pdisp1_ratex.bmp -0.12 0.04 9 1

# --> pdisp1_ratex, pdisp1_tsx.tpf, pres5

