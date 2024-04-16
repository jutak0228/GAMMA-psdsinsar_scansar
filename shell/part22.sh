#!/bin/bash

# Test step 6: Using the consistently unwrapped phases we try to correctly unwrap further pixels.
#              We use the spatially interpolated unwrapped phases of the multi-reference stack
#              layer to unwrap all other pixels and check if their unwrapping is consistent

work_dir="$1"
ref_date="$2"
rlks="$3"
azlks="$4"

cd ${work_dir}/ipta_test
ref_point_rev=`grep "1" prox_prt.txt | awk -F" " '{print $2}'`
num_row=`cat ../int/bperp_file.txt | wc -l`
echo "number of rows in ../int/bperp_file.txt is ... $num_row"

# generate mask with consistely unwrapped points
/bin/cp pmask4 pmask4_consistent
thres_msk_pt pt pmask4_consistent psigma_ts_tmp 1 0.0 0.2
# 1102031 points

expand_data_inpaint_pt pt_geo pmask4_consistent ../DEM/EQA.dem_par pdiff.unw1.corrected pt_geo - pdiff.unw1.corrected.expanded - 0 10 4 - 0
#pdisdt_pwr24 pt - ${ref_date}.rslc.par pdiff.unw1.corrected.expanded 21 ${ref_date}.rmli.par ave.rmli 6.28 3

unw_model_pt pt - pdiff00 - pdiff.unw1.corrected.expanded pdiff.unw2 ${ref_point_rev}
#pdisdt_pwr24 pt - ${ref_date}.rslc.par pdiff.unw2 21 ${ref_date}.rmli.par ave.rmli 6.28 3

# run mb_pt without temporal smoothing but using the corrected input pdiff.unw2
spf_pt pt_geo - ../DEM/EQA.dem_par pdiff.unw2 pdiff.unw2a - 2 5 0 - $ref_point_rev 1

# notice that pmask4 is now no longer indicated as we expanded the unwrapped phase to all pixels
mb_pt pt - pSLC_par itab pdiff.unw2a $ref_point_rev - itab_ts pdiff_ts_tmp pdiff_sim_tmp psigma_ts_tmp 1 phgt_out_tmp 0.0 prate_tmp pconst_tmp psigma_fit_tmp ${ref_date}.rslc.par
#pdisdt_pwr24 pt - ${ref_date}.rslc.par prate_tmp 1 ${ref_date}.rmli.par ave.rmli 62.8 3
# A number of areas (landslides, rock glaciers) with significant motion rates are clearly visible.

#pdisdt_pwr24 pt pmask4 ${ref_date}.rslc.par psigma_ts_tmp 1 ${ref_date}.rmli.par ave.rmli 3.0 3
# There are areas with psigma_ts_tmp values up to about 0.1 radian and then others with values > 0.4 radian. 
# The low values correspond to areas with fully consistent unwrapping (consistent between the redundent observations)

# we generate again the histogram of the psigma_ts values

/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.0 0.1 > log_histogram
/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.1 0.2 >> log_histogram
/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.2 0.3 >> log_histogram
/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.3 0.4 >> log_histogram
/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.4 0.5 >> log_histogram
/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.5 0.6 >> log_histogram
/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.6 0.7 >> log_histogram
/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.7 0.8 >> log_histogram
/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.8 0.9 >> log_histogram
/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.9 1.0 >> log_histogram
/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 1.0 1.1 >> log_histogram
/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 1.1 1.2 >> log_histogram
/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 1.2 1.3 >> log_histogram
/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 1.3 1.4 >> log_histogram
/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 1.4 1.5 >> log_histogram
/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 1.5 1000.5 >> log_histogram

grep "points within mask after threshold test" log_histogram > histogram

# more histogram
# -->
# points within mask after threshold test: 1233066
# points within mask after threshold test: 0
# points within mask after threshold test: 0
# points within mask after threshold test: 0
# points within mask after threshold test: 0
# points within mask after threshold test: 150277
# points within mask after threshold test: 324510
# points within mask after threshold test: 331484
# points within mask after threshold test: 442249
# points within mask after threshold test: 514818
# points within mask after threshold test: 657377
# points within mask after threshold test: 832903
# points within mask after threshold test: 967171
# points within mask after threshold test: 1042845
# points within mask after threshold test: 984142
# points within mask after threshold test: 1241515

# In the areas with large psigma_ts_tmp the presence of unwrapping errors is likely.
# We visualize the difference between pdiff.unw2a and pdiff_sim_tmp to check this.
sub_phase_pt pt - pdiff.unw2a - pdiff_sim_tmp pdphase 0 0

ras_data_pt pt - pdphase 1 $num_row ave.rmli.bmp ras/pdphase 2 $rlks $azlks -9.42 9.42 1 rmg.cm
#xv -exp -2 ras/pdphase_???.bmp &
bash ../mymontage.sh "ras/pres4_???.bmp"

unw_to_cpx_pt pt - pdiff.unw2a - pdiff.unw2a.cpx
unw_model_pt pt - pdiff.unw2a.cpx - pdiff_sim_tmp pdiff.unw2a.tmp
unw_to_cpx_pt pt - pdiff.unw2 - pdiff.unw2.cpx
unw_model_pt pt - pdiff.unw2.cpx - pdiff.unw2a.tmp pdiff.unw2.corrected

# run mb_pt without temporal smoothing but using the corrected input pdiff.unw2.corrected
spf_pt pt_geo - ../DEM/EQA.dem_par pdiff.unw2.corrected pdiff.unw2.correcteda - 2 5 0 - $ref_point_rev 1
mb_pt pt - pSLC_par itab pdiff.unw2.correcteda $ref_point_rev - itab_ts pdiff_ts_tmp pdiff_sim_tmp psigma_ts_tmp 1 phgt_out_tmp 0.0 prate_tmp pconst_tmp psigma_fit_tmp ${ref_date}.rslc.par
#pdisdt_pwr24 pt - ${ref_date}.rslc.par prate_tmp 1 ${ref_date}.rmli.par ave.rmli 62.8 3
# A number of areas (landslides, rock glaciers) with significant motion rates are clearly visible.

#pdisdt_pwr24 pt pmask4 ${ref_date}.rslc.par psigma_ts_tmp 1 ${ref_date}.rmli.par ave.rmli 3.0 3
# There are areas with psigma_ts_tmp values up to about 0.1 radian and then others with values > 0.4 radian. 
# The low values correspond to areas with fully consistent unwrapping (consistent between the redundent observations)

# we generate again the histogram of the psigma_ts values

/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.0 0.1 > log_histogram
/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.1 0.2 >> log_histogram
/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.2 0.3 >> log_histogram
/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.3 0.4 >> log_histogram
/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.4 0.5 >> log_histogram
/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.5 0.6 >> log_histogram
/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.6 0.7 >> log_histogram
/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.7 0.8 >> log_histogram
/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.8 0.9 >> log_histogram
/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.9 1.0 >> log_histogram
/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 1.0 1.1 >> log_histogram
/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 1.1 1.2 >> log_histogram
/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 1.2 1.3 >> log_histogram
/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 1.3 1.4 >> log_histogram
/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 1.4 1.5 >> log_histogram
/bin/rm pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 1.5 1000.5 >> log_histogram

grep "points within mask after threshold test" log_histogram > histogram

# more histogram
# -->
# points within mask after threshold test: 2269801
# points within mask after threshold test: 0
# points within mask after threshold test: 0
# points within mask after threshold test: 0
# points within mask after threshold test: 0
# points within mask after threshold test: 329675
# points within mask after threshold test: 507377
# points within mask after threshold test: 903107
# points within mask after threshold test: 701099
# points within mask after threshold test: 751730
# points within mask after threshold test: 863481
# points within mask after threshold test: 773565
# points within mask after threshold test: 657066
# points within mask after threshold test: 476405
# points within mask after threshold test: 292478
# points within mask after threshold test: 196572

# So the number of values with consistent unwrapping has increased from 1231570 to 2269801
# Notice that consistently unwrapped does not necessarily mean correct or having high coherence.

# We generate a mask of consistently unwrapped points
if [ -e  pmask_consistent ];then /bin/rm pmask_consistent; fi
thres_msk_pt pt pmask_consistent psigma_ts_tmp 1 0.0 0.2
# --> 2269801 points

# --> The unwrapped differential interferometric phases for the multi-reference
#     stack are determined.

# --> pdiff.unw2.corrected (consistently unwrapped within pmask_consistent)

