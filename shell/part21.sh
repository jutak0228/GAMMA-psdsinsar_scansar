#!/bin/bash

# Test step 5: Check and improve unwrapping consistency using mb_pt

work_dir="$1"
ref_date="$2"
rlks="$3"
azlks="$4"

cd ${work_dir}/ipta_test

# subtract reference point phase from each layer:
ref_point_rev=`grep "1" prox_prt.txt | awk -F" " '{print $2}'`
num_row=`cat ../int/bperp_file.txt | wc -l`
echo "number of rows in ../int/bperp_file.txt is ... $num_row"

spf_pt pt_geo pmask4 ../DEM/EQA.dem_par pdiff.unw1 pdiff.unw1a - 2 15 0 - $ref_point_rev 1

# Running mb_pt without temporal smoothing of the time series is recommended at
# this stage (at least in addition to running mb_pt with temporal smoothing) to
# get a very useful quality check on the consistency of the unwrapping of the
# differential interferometric phases used as input. In the case of consistency
# the psigma_ts value is very small (<< 1 radian), while it is of the order of
# 1 radian or larger for locations with one or several inconsistencies in the
# unwrapping. For multi-look phases the standard deviation is also potentially
# higher than for single-look phases.

# run mb_pt without temporal smoothing
mb_pt pt pmask4 pSLC_par itab pdiff.unw1a $ref_point_rev - itab_ts pdiff_ts_tmp pdiff_sim_tmp psigma_ts_tmp 1 phgt_out_tmp 0.0 prate_tmp pconst_tmp psigma_fit_tmp ${ref_date}.rslc.par
#pdisdt_pwr24 pt pmask4 ${ref_date}.rslc.par prate_tmp 1 ${ref_date}.rmli.par ave.rmli 62.8 3
# A number of areas (landslides, rock glaciers) with significant motion rates are clearly visible.

#pdisdt_pwr24 pt pmask4 ${ref_date}.rslc.par psigma_ts_tmp 1 ${ref_date}.rmli.par ave.rmli 3.0 3
# There are areas with psigma_ts_tmp values up to about 0.1 radian and then others with values > 0.4 radian. 
# The low values correspond to areas with fully consistent unwrapping (consistent between the redundent observations)

# to better understand the result we generate a histogram of the psigma_ts values

/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.0 0.1 >> log_histogram
/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.1 0.2 >> log_histogram
/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.2 0.3 >> log_histogram
/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.3 0.4 >> log_histogram
/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.4 0.5 >> log_histogram
/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.5 0.6 >> log_histogram
/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.6 0.7 >> log_histogram
/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.7 0.8 >> log_histogram
/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.8 0.9 >> log_histogram
/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.9 1.0 >> log_histogram
/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 1.0 1.1 >> log_histogram
/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 1.1 1.2 >> log_histogram
/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 1.2 1.3 >> log_histogram
/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 1.3 1.4 >> log_histogram
/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 1.4 1.5 >> log_histogram
/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 1.5 1000.5 >> log_histogram

grep "points within mask after threshold test" log_histogram > histogram

# more histogram
# -->
# points within mask after threshold test: 821721
# points within mask after threshold test: 0
# points within mask after threshold test: 0
# points within mask after threshold test: 0
# points within mask after threshold test: 0
# points within mask after threshold test: 137190
# points within mask after threshold test: 151159
# points within mask after threshold test: 128426
# points within mask after threshold test: 52745
# points within mask after threshold test: 15355
# points within mask after threshold test: 1429
# points within mask after threshold test: 26
# points within mask after threshold test: 3
# points within mask after threshold test: 2
# points within mask after threshold test: 0
# points within mask after threshold test: 0

# In the areas with large psigma_ts_tmp the presence of unwrapping errors is likely.
# We visualize the difference between pdiff.unw1a and pdiff_sim_tmp to check this.
sub_phase_pt pt pmask4 pdiff.unw1a - pdiff_sim_tmp pdphase 0 0

ras_data_pt pt pmask4 pdphase 1 $num_row ave.rmli.bmp ras/pdphase 2 $rlks $azlks -9.42 9.42 1 rmg.cm
#xv -exp -2 ras/pdphase_???.bmp &
bash ../mymontage.sh "ras/pdphase_???.bmp"

# An obvious difference is observed in layer 51 (e.g. at the top of the image).
#pdisdt_pwr24 pt pmask4 ${ref_date}.rslc.par pdphase 51 ${ref_date}.rmli.par ave.rmli 12.6 3
# The phase difference is around -3.4. At a reduced level the pattern is also visible in some other layers
# near layer 51 (e.g. 53) with the other sign. So it is likely that
# layer 51 is the one not being consistent with the other. 
# We correct layer 51 (and all other layers using the simulated phase as model to redetermine the ambiguity number
unw_to_cpx_pt pt pmask4 pdiff.unw1a - pdiff.unw1a.cpx
unw_model_pt pt pmask4 pdiff.unw1a.cpx - pdiff_sim_tmp pdiff.unw1a.tmp
unw_to_cpx_pt pt pmask4 pdiff.unw1 - pdiff.unw1.cpx
unw_model_pt pt pmask4 pdiff.unw1.cpx - pdiff.unw1a.tmp pdiff.unw1.corrected

# run mb_pt without temporal smoothing but using the corrected input pdiff.unw1.corrected
spf_pt pt_geo pmask4 ../DEM/EQA.dem_par pdiff.unw1.corrected pdiff.unw1.correcteda - 2 15 0 - $ref_point_rev 1
mb_pt pt pmask4 pSLC_par itab pdiff.unw1.correcteda $ref_point_rev - itab_ts pdiff_ts_tmp pdiff_sim_tmp psigma_ts_tmp 1 phgt_out_tmp 0.0 prate_tmp pconst_tmp psigma_fit_tmp ${ref_date}.rslc.par
#pdisdt_pwr24 pt pmask4 ${ref_date}.rslc.par prate_tmp 1 ${ref_date}.rmli.par ave.rmli 62.8 3
# A number of areas (landslides, rock glaciers) with significant motion rates are clearly visible.

#pdisdt_pwr24 pt pmask4 ${ref_date}.rslc.par psigma_ts_tmp 1 ${ref_date}.rmli.par ave.rmli 3.0 3
# There are areas with psigma_ts_tmp values up to about 0.1 radian and then others with values > 0.4 radian. 
# The low values correspond to areas with fully consistent unwrapping (consistent between the redundent observations)

# we generate again the histogram of the psigma_ts values

/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.0 0.1 > log_histogram
/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.1 0.2 >> log_histogram
/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.2 0.3 >> log_histogram
/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.3 0.4 >> log_histogram
/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.4 0.5 >> log_histogram
/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.5 0.6 >> log_histogram
/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.6 0.7 >> log_histogram
/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.7 0.8 >> log_histogram
/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.8 0.9 >> log_histogram
/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 0.9 1.0 >> log_histogram
/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 1.0 1.1 >> log_histogram
/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 1.1 1.2 >> log_histogram
/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 1.2 1.3 >> log_histogram
/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 1.3 1.4 >> log_histogram
/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 1.4 1.5 >> log_histogram
/bin/cp pmask4 pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts_tmp 1 1.5 1000.5 >> log_histogram

grep "points within mask after threshold test" log_histogram > histogram

# more histogram
# -->
# points within mask after threshold test: 1102031
# points within mask after threshold test: 0
# points within mask after threshold test: 0
# points within mask after threshold test: 0
# points within mask after threshold test: 0
# points within mask after threshold test: 39864
# points within mask after threshold test: 55962
# points within mask after threshold test: 84948
# points within mask after threshold test: 21111
# points within mask after threshold test: 3590
# points within mask after threshold test: 547
# points within mask after threshold test: 3
# points within mask after threshold test: 0
# points within mask after threshold test: 0
# points within mask after threshold test: 0
# points within mask after threshold test: 0

# So the number of values with consistent unwrapping has increased from 821721 to 1102031
