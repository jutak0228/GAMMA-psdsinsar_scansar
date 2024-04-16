#!/bin/bash

# Test step 10: Generation of spatially filtered time-series and related average rates
#               --> pdiff1.tsx_spf5, pdefx_spf5, (and pmask_final_spf)

work_dir="$1"
ref_date="$2"
rlks="$3"
azlks="$4"

cd ${work_dir}/ipta_test
ref_point_rev=`grep "1" prox_prt.txt | awk -F" " '{print $2}'`
num_row=`cat ../int/bperp_file.txt | wc -l`
echo "number of rows in ../int/bperp_file.txt is ... $num_row"

# apply a slight spatial filtering at time series level we include 9 spatial
# points into the filtering but tolerate somewhat larger distances
spf_pt pt_geo pmask_final ../DEM/EQA.dem_par pdiff1.tsx pdiff1.tsx_spf5 - 2 25 0 9

# for some points it is there may be less than 9 pixels in the search area, accordingly
# no filtered solution is calculated. We set the mask value in pmask_final_spf to 0
/bin/cp pmask_final pmask_final_spf
/bin/rm ptmp1
lin_comb_pt pt pmask_final pdiff1.tsx_spf5 1 pdiff1.tsx_spf5 1 ptmp1 1 1000. 0. 0. 2 0
thres_msk_pt pt pmask_final_spf ptmp1 1 999 1001
# 1560872 (pmask_final and pmask_final_spf are identical)

# redetermine average rate
spf_pt pt_geo pmask_final ../DEM/EQA.dem_par pdiff1.tsx_spf5 pdiff1.tsx_spf5_a - 2 15 0 - $ref_point_rev 0
def_mod_pt pt pmask_final pSLC_par - itab_ts pbase_ts 0 pdiff1.tsx_spf5_a 0 $ref_point_rev presx_spf5 pdhx_spf5 pdefx_spf5 punwx_spf5 psigmax_spf5 pmaskx_spf5 100. -0.5 0.5 3.0 5 pdh_errx_spf5 pdef_errx_spf5

# calculate temporal coherence
cct_pt pt pmask_final ${ref_date}.rslc.par presx_spf5 pcctx_spf5 2 0.0 0 15

# compare avarege rates with single-look average rates:
#pdis2dt pt pmask_final ${ref_date}.rslc.par pdisp1_ratex 1 pdefx_spf5 1 ${ref_date}.rmli.par 0.10 0
# --> the spatial filtering of the time series results in a nice smoothing of the average rate estimates

#prasdt_pwr24 pt pmask_final ${ref_date}.rslc.par pdefx_spf5 1 ${ref_date}.rmli.par ave.rmli 0.25 1

# convert phase values and rates to displacement values and rates
dispmap_pt pt pmask_final pSLC_par itab_ts pdiff1.tsx_spf5 phgt4 pdisp1.tsx_spf5 0

# --> pdefx_spf5, pdisp1.tsx_spf5

# compare average rates for unfiltered and filtered solution
dis2ras pdefx_spf5.bmp pdisp1_ratex.bmp &

# compare time series for unfiltered and filtered solution
dis_data pt pmask_final pSLC_par itab_ts 3 pdisp1_tsx pdisp1_tsx.tpf pdisp1.tsx_spf5 0 pdisp1_ratex.bmp -0.12 0.04 9 1

#               --> pdiff1.tsx_spf5, pdefx_spf5, (and pmask_final_spf)

