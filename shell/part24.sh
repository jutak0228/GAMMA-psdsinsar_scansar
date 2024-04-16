#!/bin/bash

# Test step 8: Remove outliers directly based on spatial consistency of average deformation rate;
# do this in 2 iterations

work_dir="$1"
ref_date="$2"
rlks="$3"
azlks="$4"

cd ${work_dir}/ipta_test
ref_point_rev=`grep "1" prox_prt.txt | awk -F" " '{print $2}'`
num_row=`cat ../int/bperp_file.txt | wc -l`
echo "number of rows in ../int/bperp_file.txt is ... $num_row"

# We already removed less reliable parts of the result based on the temporal coherence

# Here we remove now outliers in the result directly based on the spatial consistency of average
# deformation rate; we do this in 2 iterations.

# convert average phase rate to average LOS displacement rate (pratex --> pdisp1_ratex)
dispmap_pt pt pmask_050x pSLC_par itab_ts pratex phgt4 pdisp1_ratex 0

##########################

# first iteration:

# An outlier is defined as a value for which pdisp1_ratex deviates significantly from the values of its spatial neighborhood
# To identify outliers we apply a spatial filtering and determine and threshold for each point the deviation from the filtered value.

spf_pt pt_geo pmask_050x ../DEM/EQA.dem_par pdisp1_ratex pdisp1_ratex.spf5 1 2 25 0 9
lin_comb_pt pt pmask_050x pdisp1_ratex 1 pdisp1_ratex.spf5 1 pddisp1_ratex 1 0. 1. -1. 2 0
#pdisdt_pwr24 pt pmask_050x ${ref_date}.rslc.par pddisp1_ratex 1 ${ref_date}.rmli.par ave.rmli 0.10 1

# remove outliers, but do not mask very fast areas (pmask_fast1)

/bin/cp pmask_050x pmask_not_outlier
thres_msk_pt pt pmask_not_outlier pddisp1_ratex 1 -0.025 0.025
# 1600970 points
#pdisdt_pwr24 pt pmask_not_outlier ${ref_date}.rslc.par pdisp1_ratex.spf5 1 ${ref_date}.rmli.par ave.rmli 0.25 1

# combine pmask_fast1 and pmask_not_outlier (to avoid masking relevant information)
/bin/rm ptmp1 ptmp2 ptmp3
lin_comb_pt pt pmask_fast1 pdisp1_ratex - pdisp1_ratex - ptmp1 - 10. 0. 0. 2 0
lin_comb_pt pt pmask_not_outlier pdisp1_ratex - pdisp1_ratex - ptmp2 - 10. 0. 0. 2 0
lin_comb_pt pt -  ptmp2 - ptmp1 - ptmp3 - 0. 1. 1. 2 1
/bin/cp pmask_not_outlier pmask_not_outlier1
thres_msk_pt pt pmask_not_outlier1 ptmp3 1 5 25
# 1600970 points
#pdisdt_pwr24 pt pmask_not_outlier1 ${ref_date}.rslc.par pdisp1_ratex 1 ${ref_date}.rmli.par ave.rmli 0.25 1

# remove isolated points
pt_density pt pmask_not_outlier1 ${ref_date}.rslc.par pt_density15 15
#pdisdt_pwr24 pt pmask_not_outlier1 ${ref_date}.rslc.par pt_density15 1 ${ref_date}.rmli.par ave.rmli 100 1
/bin/cp pmask_not_outlier1 pmask_not_outlier2
thres_msk_pt pt pmask_not_outlier2 pt_density15 1 1.5 10000
# 1593188 points
#pdisdt_pwr24 pt pmask_not_outlier2 ${ref_date}.rslc.par pdisp1_ratex 1 ${ref_date}.rmli.par ave.rmli 0.25 1

##########################

# second iteration:
/bin/cp pmask_not_outlier2 pmask_050xA

spf_pt pt_geo pmask_050xA ../DEM/EQA.dem_par pdisp1_ratex pdisp1_ratex.spf5 1 2 25 0 9
lin_comb_pt pt pmask_050xA pdisp1_ratex 1 pdisp1_ratex.spf5 1 pddisp1_ratex 1 0. 1. -1. 2 0
#pdisdt_pwr24 pt pmask_050xA ${ref_date}.rslc.par pddisp1_ratex 1 ${ref_date}.rmli.par ave.rmli 0.10 1

# remove outliers, but do not mask very fast areas (pmask_fast1)

/bin/cp pmask_050xA pmask_not_outlier
thres_msk_pt pt pmask_not_outlier pddisp1_ratex 1 -0.025 0.025
# 1561978 points
#pdisdt_pwr24 pt pmask_not_outlier ${ref_date}.rslc.par pdisp1_ratex.spf5 1 ${ref_date}.rmli.par ave.rmli 0.25 3

# combine pmask_fast1 and pmask_not_outlier (to avoid masking relevant information)
/bin/rm ptmp1 ptmp2 ptmp3
lin_comb_pt pt pmask_fast1 pdisp1_ratex - pdisp1_ratex - ptmp1 - 10. 0. 0. 2 0
lin_comb_pt pt pmask_not_outlier pdisp1_ratex - pdisp1_ratex - ptmp2 - 10. 0. 0. 2 0
lin_comb_pt pt -  ptmp2 - ptmp1 - ptmp3 - 0. 1. 1. 2 1
/bin/cp pmask_not_outlier pmask_not_outlier1
thres_msk_pt pt pmask_not_outlier1 ptmp3 1 5   25
# 1561978 points
#pdisdt_pwr24 pt pmask_not_outlier1 ${ref_date}.rslc.par pdisp1_ratex 1 ${ref_date}.rmli.par ave.rmli 0.25 1

# remove isolated points
pt_density pt pmask_not_outlier1 ${ref_date}.rslc.par pt_density15 15
#pdisdt_pwr24 pt pmask_not_outlier1 ${ref_date}.rslc.par pt_density15 1 ${ref_date}.rmli.par ave.rmli 100 1
/bin/cp pmask_not_outlier1 pmask_not_outlier2
thres_msk_pt pt pmask_not_outlier2 pt_density15 1 1.5  10000
# 1560872 points
#pdisdt_pwr24 pt pmask_not_outlier2 ${ref_date}.rslc.par pdisp1_ratex 1 ${ref_date}.rmli.par ave.rmli 0.25 0
#pdisdt_pwr24 pt pmask_not_outlier2 ${ref_date}.rslc.par pdisp1_ratex 1 ${ref_date}.rmli.par ave.rmli 0.10 0

/bin/cp pmask_not_outlier2 pmask_final

# determine linear LOS deformation rate for this result
base_orbit_pt pSLC_par itab_ts - pbase_ts
spf_pt pt_geo pmask_final ../DEM/EQA.dem_par pdiff1.tsx pdiff1.tsx_a - 2 15 0 - $ref_point_rev 0
def_mod_pt pt pmask_final pSLC_par - itab_ts pbase_ts 0 pdiff1.tsx_a 0 $ref_point_rev presx pdhx pdefx punwx psigmax pmaskx 100. -0.5 0.5 3.0 5 pdh_errx pdef_errx

# calculate temporal coherence
cct_pt pt pmask_final ${ref_date}.rslc.par presx pcctx 2 0.0 0 15

