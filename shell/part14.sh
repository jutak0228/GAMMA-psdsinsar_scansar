#!/bin/bash

# Part 14 In the following the phases are converted into a deformation time series and
# atmospheric phases; this is done using the following assumption:

work_dir="$1"
ref_date="$2"
rlks="$3"
azlks="$4"
ref_point="$5"
dem_name="$6"

cd ipta

num_row=`cat ../int/bperp_file.txt | wc -l`
echo "number of rows in ../int/bperp_file.txt is ... $num_row"

# Approach: patm estimation based on multi-reference pairs
# - It is assumed that the atmospheric phase is spatially smooth with a linearly height dependent hydrostatic part
# - It is assumed that the deformation is temporally smooth (but in areas with
#   high deformations rates (i.e. > 10.0 radian/year) or very locally (with difference
#   from spatial average > 1.0 radian/year) it can be non-uniform)
# - Based on the linear deformation rate over the entire period the
#   area that has no strong deformation nor local deformation is determined.
# - Based on this area, the atmospheric phase patm is estimated individually
#   for each layer of the multi-reference stack.
# - For a short total observation interval (e.g. 5 months S1 data) this
#   reduces the atmospheric effects on the estimation of the linear deformation rate and
#   on the deformation time series significantly - on the other hand
#   spatially smooth slow deformation is not included (but shifted into
#   the atmospheric phase)

# The atmospheric path delay phase is individually estimated for each pair
# of the multi-reference stack. To constrain the estimation of the atmospheric
# path delays to "almost stable" areas, we need to generate a mask.

# create model of atmospheric phase and subtract it
atm_mod_pt pt pmask5 pdiff.unw1 phgt4 patm_mod
sub_phase_pt pt pmask5 pdiff.unw1 - patm_mod pdiff.unw2 0 0

# subtract reference point phase from each layer:
spf_pt pt_geo pmask5 ../DEM/EQA.dem_par pdiff.unw2 pdiff.unwa - 2 5 0 - $ref_point 1

# Running mb_pt without temporal smoothing of the time series is recommended at
# this stage (at least in addition to running mb_pt with temporal smoothing) to
# get a very useful quality check on the consistency of the unwrapping of the
# differential interferometric phases used as input. In the case of consistency
# the psigma_ts value is very small (<< 1 radian), while it is of the order of
# 1 radian or larger for locations with one or several inconsistencies in the
# unwrapping. For multi-look phases the standard deviation is also potentially
# higher than for single-look phases.

# run without spatial smoothing
mb_pt pt pmask5 pSLC_par itab pdiff.unwa $ref_point - itab_ts pdiff_ts_tmp1 pdiff_sim_tmp1 psigma_ts_tmp1 1 phgt_out_tmp1 0.0 prate_tmp1 pconst_tmp1 psigma_fit_tmp1 ${ref_date}.rslc.par
#pdisdt_pwr24 pt pmask5 ${ref_date}.rslc.par prate_tmp1 1 ${ref_date}.rmli.par ave.rmli 62.8 3
#pdisdt_pwr24 pt pmask5 ${ref_date}.rslc.par psigma_ts_tmp1 1 ${ref_date}.rmli.par ave.rmli 3.0 3

# There are areas with psigma_ts_tmp1 values around 0.1 radian and then others with
# values > 0.7 radian. The low values correspond to areas with fully consistent unwrapping
# (consistent between the redundent observations)

############

# Based on the results of mb_pt we apply a correction of the unwrapping

# In the areas with large psigma_ts_tmp the presence of unwrapping errors is likely.
# We visualize the difference between pdiff.unwa and pdiff_sim_tmp1 to check this.
sub_phase_pt pt pmask5 pdiff.unwa - pdiff_sim_tmp1 pdphase1 0 0

ras_data_pt pt pmask5 pdphase1 1 $num_row ave.rmli.bmp ras/pdphase1 2 $rlks $azlks -6.28 6.28 1 rmg.cm
#xv -exp -2 ras/pdphase1_???.bmp &
# bash ../mymontage.sh "ras/pdphase1_???.bmp"

# An obvious difference is observed in layer 4 (top right around pixel (691,257))
#pdisdt_pwr24 pt pmask5 ${ref_date}.rslc.par pdphase1 4 ${ref_date}.rmli.par ave.rmli 12.6 3
#pdisdt_pwr24 pt pmask5 ${ref_date}.rslc.par pdphase1 6 ${ref_date}.rmli.par ave.rmli 12.6 3
# The phase difference is around -4.0. The pattern is also visible in some other layers
# near layer 4 (e.g. layer 6) with the other sign and a lower level. So it is likely that
# layer 4 is the one not being consistent with the other. We correct layer 4 using the
# simulated phase as the model for the unwrapping:
# We use a very small phase (0.0001 radian) as the model to unwrap the rewrapped pdphase

unw_to_cpx_pt pt pmask5 pdphase1 - pdphase1.cpx
lin_comb_pt pt pmask5 pdphase1 - pdphase1 - pmodel0 - 0.0001 0. 0. 2 0

unw_model_pt pt pmask5 pdphase1.cpx - pmodel0 pdphase1.cpx.unw
#pdisdt_pwr24 pt pmask5 ${ref_date}.rslc.par pdphase1.cpx.unw 4 ${ref_date}.rmli.par ave.rmli 12.6 3
lin_comb_pt pt pmask5 pdphase1.cpx.unw - pdphase1 - ppcorrection1 - 0.0 1. -1. 2 0
#pdisdt_pwr24 pt pmask5 ${ref_date}.rslc.par ppcorrection1 4 ${ref_date}.rmli.par ave.rmli 12.6 3
# (0.0 values are not shown)

# In the same way possible corrections were also determined for all other layers
ras_data_pt pt pmask5 ppcorrection1 1 $num_row ave.rmli.bmp ras/ppcorrection1 2 $rlks $azlks -9.42 9.42 1 rmg.cm
#xv -exp -2 ras/ppcorrection1_???.bmp &
# bash ../mymontage.sh "ras/ppcorrection1_???.bmp"

# We add these ambiguity corrections to pdiff.unw to get a corrected version of pdiff.unw (namely pdiff.unw.corr1)
lin_comb_pt pt pmask5 pdiff.unw - ppcorrection1 - pdiff.unw.corr1 - 0.0 1. 1. 2 1

# the provided script "unwrapping_correction_mb_pt.py" performs the same steps as shown above
# and is used to iterate the process 2 more times
../input_files_orig/unwrapping_correction_mb_pt.py pt pSLC_par itab pdiff.unw.corr1 $ref_point ${ref_date}.rslc.par pdiff.unw.corr2 --pmask pmask5 --pdh_sim pdh4.sim_unw --phgt phgt4
../input_files_orig/unwrapping_correction_mb_pt.py pt pSLC_par itab pdiff.unw.corr2 $ref_point ${ref_date}.rslc.par pdiff.unw.corr3 --pmask pmask5 --pdh_sim pdh4.sim_unw --phgt phgt4

############
# using pdiff.unw.corr3 we redo the first steps of 14
sub_phase_pt pt pmask5 pdiff.unw.corr3 - pdh4.sim_unw pdiff.unw1 0 0
atm_mod_pt pt pmask5 pdiff.unw1 phgt4 patm_mod
sub_phase_pt pt pmask5 pdiff.unw1 - patm_mod pdiff.unw2 0 0
spf_pt pt_geo pmask5 ../DEM/EQA.dem_par pdiff.unw2 pdiff.unwa - 2 5 0 - $ref_point 1
mb_pt pt pmask5 pSLC_par itab pdiff.unwa $ref_point - itab_ts pdiff_ts_tmp1 pdiff_sim_tmp1 psigma_ts_tmp1 1 phgt_out_tmp1 0.0 prate_tmp1 pconst_tmp1 psigma_fit_tmp1 ${ref_date}.rslc.par

# pdisdt_pwr pt pmask5 20190809.rslc.par prate_tmp1 1 20190809.rmli.par ave.rmli -31.4 31.4
# There are no obvious changes in prate_tmp1 from the unwrapping correction.
# A number of areas (landslides, rock glaciers) with significant
# motion rates are clearly visible.

# pdisdt_pwr pt pmask5 20190809.rslc.par psigma_ts_tmp1 1 20190809.rmli.par ave.rmli -1.5 1.5
# psigma_ts_tmp1 reduced in some areas.
# There are areas with psigma_ts_tmp1 values around 0.1 radian and a few area with
# values > 0.7 radian. The low values correspond to areas with fully consistent unwrapping
# (consistent between the redundent observations)

# In the areas with large psigma_ts_tmp the presence of unwrapping errors is likely.
# We visualize the difference between pdiff.unwa.spf pdiff_sim_tmp to check this.
sub_phase_pt pt pmask5 pdiff.unwa - pdiff_sim_tmp1 pdphase2 0 0

ras_data_pt pt pmask5 pdphase2 1 $num_row ave.rmli.bmp ras/pdphase2 2 $rlks $azlks -6.28 6.28 1 rmg.cm
# xv -exp -2 ras/pdphase1_???.bmp &

# e.g. layer 34 has clearly improved
# pdis2dt_pwr pt pmask5 20190809.rslc.par pdphase1 34 pdphase2 34 20190809.rmli.par ave.rmli -6.28 6.28 1 rmg.cm

# we generate a mask that only includes small psigma_ts_tmp1 values (< 0.4 radian)
/bin/cp pmask5 pmask_low_sigma
thres_msk_pt pt pmask_low_sigma psigma_ts_tmp1 1 0.0 0.4
# 97252 are in pmask_low_sigma
# pdisdt_pwr pt pmask_low_sigma 20190809.rslc.par prate_tmp1 1 20190809.rmli.par ave.rmli -31.4 31.4

# the reduction with this threshold is very significant.
# The reason is that the psigma_ts is higher than 0.5 for many multi-look phases,
# in spite of (most likely) consistent unwrapping because of non-zero closure
# phase ( phase(AB) + phase(BC) - phase(AC) is not equal to 0.0 ).

# To reduce the level of this effect we apply an additional slight spatial
# filtering before applying mb_pt.

############################################

# To reduce the effect of non-zero closure phase of multi-look phases
# we apply a spatial filtering with a small window.

sub_phase_pt pt pmask5 pdiff.unw.corr3 - pdh4.sim_unw pdiff.unw1 0 0
atm_mod_pt pt pmask5 pdiff.unw1 phgt4 patm_mod
sub_phase_pt pt pmask5 pdiff.unw1 - patm_mod pdiff.unw2 0 0
spf_pt pt_geo pmask5 ../DEM/EQA.dem_par pdiff.unw2 pdiff.unwa - 2 5 0 - $ref_point 1
spf_pt pt_geo pmask5 ../DEM/EQA.dem_par pdiff.unwa pdiff.unwa.spf - 2 15 0
mb_pt pt pmask5 pSLC_par itab pdiff.unwa.spf $ref_point - itab_ts pdiff_ts_tmp pdiff_sim_tmp psigma_ts_tmp 1 phgt_out_tmp 0.0 prate_tmp pconst_tmp psigma_fit_tmp ${ref_date}.rslc.par

# pdisdt_pwr pt pmask5 20190809.rslc.par prate_tmp 1 20190809.rmli.par ave.rmli -31.4 31.4
# A number of areas (landslides, rock glaciers) with significant
# motion rates are clearly visible.

# pdisdt_pwr pt pmask5 20190809.rslc.par psigma_ts_tmp 1 20190809.rmli.par ave.rmli -1.5 1.5
# psigma_ts_tmp2 is clearly reduced as a consequence of the filtering

# We check again the unwrapping consistency here:
sub_phase_pt pt pmask5 pdiff.unwa.spf - pdiff_sim_tmp pdphase3 0 0

ras_data_pt pt pmask5 pdphase3 1 $num_row ave.rmli.bmp ras/pdphase3 2 $rlks $azlks -6.28 6.28 1 rmg.cm
# xv -exp -2 ras/pdphase3_???.bmp &

# we don't apply further correction to the unwrapping

# we generate a mask that only includes small psigma_ts_tmp values (< 0.4 radian)
/bin/cp pmask5 pmask_low_sigma
thres_msk_pt pt pmask_low_sigma psigma_ts_tmp 1 0.0 0.4
# 141407 are in pmask_low_sigma
#pdisdt_pwr24 pt pmask_low_sigma ${ref_date}.rslc.par prate_tmp 1 ${ref_date}.rmli.par ave.rmli 62.8 3

#########################

# The deformation rate estimates show a few areas with fast movements, including the Moosfluh landslide (about 40 radian/year).
# For areas that are most likely stable (or very slowly moving) phase rates of up to about 12 radian/year are observed. This corresponds to about 6 cm/year. Such high values are observed because of the short total time span of the data set of about 5 months. In an interferogram of 5 months an atmospheric phase of PI causes already an error in the estimated rate of 7.5 radian/year

# To estimate atmospheric phases we exclude:
# a) large fast moving areas
# b) areas that show a significantly different motion than its neighborhood (local phenomena)

# determine local relative phase rate pdrate
spf_pt pt_geo pmask_low_sigma ../DEM/EQA.dem_par prate_tmp prate_spf35 - 2 35 1
sub_phase_pt pt pmask_low_sigma prate_tmp - prate_spf35 pdrate 0 0
#pdisdt_pwr24 pt pmask_low_sigma ${ref_date}.rslc.par pdrate 1 ${ref_date}.rmli.par ave.rmli 12.56 3

# a)
/bin/cp pmask_low_sigma pmask_slow1
thres_msk_pt pt pmask_slow1 prate_spf35 1 -12.0 12.0  # --> 140206
#pdisdt_pwr24 pt pmask_slow1 ${ref_date}.rslc.par prate_tmp 1 ${ref_date}.rmli.par ave.rmli 62.8 3
#pdisdt_pwr24 pt - ${ref_date}.rslc.par prate_tmp 1 ${ref_date}.rmli.par ave.rmli 62.8 3
# --> 140206 points remained

# b)
lin_comb_pt pt pmask_slow1 prate_tmp - prate_tmp - prate_tmp_slow1 - 0.0 1. 0. 2 0
lin_comb_pt pt - prate_tmp - prate_tmp_slow1 - prate_tmp_slow2 - 0.00001 1. -1. 2 1
spf_pt pt_geo pmask_low_sigma ../DEM/EQA.dem_par prate_tmp_slow2 prate_tmp_slow2_spf35 - 2 35 1
# sub_phase_pt pt pmask_slow1 prate_tmp - prate_tmp_slow2_spf35 pdrate2 0 0

/bin/cp pmask_low_sigma pmask_slow
thres_msk_pt pt pmask_slow prate_tmp_slow2_spf35 1 -1.0 1.0 # --> 139264
thres_msk_pt pt pmask_slow pdrate 1 -1.0 1.0                # --> 121739
#pdisdt_pwr24 pt pmask_slow ${ref_date}.rslc.par prate_tmp 1 ${ref_date}.rmli.par ave.rmli 62.8 3

# visualize
lin_comb_pt pt pmask_slow prate_tmp - prate_tmp - prate_tmp_slow3 - 0.0 1. 0. 2 0
# pdis2dt_pwr pt pmask_low_sigma 20190809.rslc.par prate_tmp 1 prate_tmp_slow3 1 20190809.rmli.par ave.rmli -12.56 12.56 &

# --> use area of pmask_slow to estimate atm phases in multi-reference stack

###############

# Spatially filter and interpolate multi-reference stack unwrapped phase
# (considering only area without strong deformation nor local deformation)

rm -f ptmp1
fspf_pt pt_geo pmask_slow ../DEM/EQA.dem_par pdiff.unwa ptmp1 - 2 75 1
expand_data_inpaint_pt pt_geo pmask_slow ../DEM/EQA.dem_par ptmp1 pt_geo - patm - 0 10 4 - 0
#pdisdt_pwr24 pt - ${ref_date}.rslc.par patm 21 ${ref_date}.rmli.par ave.rmli 6.28 3

# subtract atmospheric path delay from pdiff.unw1
sub_phase_pt pt pmask5 pdiff.unw1 - patm_mod pdiff.unw2 0 0
sub_phase_pt pt pmask5 pdiff.unw2 - patm pdiff.unw3 0 0
#pdisdt_pwr24 pt - ${ref_date}.rslc.par pdiff.unw3 21 ${ref_date}.rmli.par ave.rmli 6.28 3

# subtract reference point phase from each layer:
spf_pt pt_geo pmask_slow ../DEM/EQA.dem_par pdiff.unw3 pdiff.unw3a - 2 5 0 - $ref_point 1

# run mb_pt without temporal smoothing (and without spatial filtering)
mb_pt pt pmask5 pSLC_par itab pdiff.unw3a $ref_point - itab_ts pdiff_ts pdiff_sim psigma_ts 1 phgt_out 0.0 prate pconst psigma_fit ${ref_date}.rslc.par

#pdisdt_pwr24 pt pmask5 ${ref_date}.rslc.par psigma_ts 1 ${ref_date}.rmli.par ave.rmli 3.0 2
# For much of the area psigma_ts is small. This indicates that the
# deviation of the multi-reference stack phases from the determined time series
# model is small, as can also be confirmed by visualizing these differences

# to better understand the result we generate a histogram of the psigma_ts values
# and do this separartely for the single-look and multi-look phases

/bin/cp pmask_single pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 0.0 0.1 > log_sl
/bin/cp pmask_single pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 0.1 0.2 >> log_sl
/bin/cp pmask_single pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 0.2 0.3 >> log_sl
/bin/cp pmask_single pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 0.3 0.4 >> log_sl
/bin/cp pmask_single pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 0.4 0.5 >> log_sl
/bin/cp pmask_single pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 0.5 0.6 >> log_sl
/bin/cp pmask_single pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 0.6 0.7 >> log_sl
/bin/cp pmask_single pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 0.7 0.8 >> log_sl
/bin/cp pmask_single pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 0.8 0.9 >> log_sl
/bin/cp pmask_single pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 0.9 1.0 >> log_sl
/bin/cp pmask_single pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 1.0 1.1 >> log_sl
/bin/cp pmask_single pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 1.1 1.2 >> log_sl
/bin/cp pmask_single pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 1.2 1.3 >> log_sl
/bin/cp pmask_single pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 1.3 1.4 >> log_sl
/bin/cp pmask_single pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 1.4 1.5 >> log_sl
/bin/cp pmask_single pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 1.5 1000.5 >> log_sl
grep "points within mask after threshold test" log_sl > table_sl

/bin/cp pmask_multilook pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 0.0 0.1 > log_ml
/bin/cp pmask_multilook pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 0.1 0.2 >> log_ml
/bin/cp pmask_multilook pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 0.2 0.3 >> log_ml
/bin/cp pmask_multilook pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 0.3 0.4 >> log_ml
/bin/cp pmask_multilook pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 0.4 0.5 >> log_ml
/bin/cp pmask_multilook pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 0.5 0.6 >> log_ml
/bin/cp pmask_multilook pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 0.6 0.7 >> log_ml
/bin/cp pmask_multilook pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 0.7 0.8 >> log_ml
/bin/cp pmask_multilook pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 0.8 0.9 >> log_ml
/bin/cp pmask_multilook pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 0.9 1.0 >> log_ml
/bin/cp pmask_multilook pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 1.0 1.1 >> log_ml
/bin/cp pmask_multilook pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 1.1 1.2 >> log_ml
/bin/cp pmask_multilook pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 1.2 1.3 >> log_ml
/bin/cp pmask_multilook pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 1.3 1.4 >> log_ml
/bin/cp pmask_multilook pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 1.4 1.5 >> log_ml
/bin/cp pmask_multilook pmask_tmp; thres_msk_pt pt pmask_tmp psigma_ts 1 1.5 1000.5 >> log_ml
grep "points within mask after threshold test" log_ml > table_ml

paste table_sl table_ml > table_sl_and_ml

# more table_sl_and_ml

# points within mask after threshold test: 67208  points within mask after threshold test: 45994
# points within mask after threshold test: 4540   points within mask after threshold test: 10740
# points within mask after threshold test: 92     points within mask after threshold test: 8382
# points within mask after threshold test: 21     points within mask after threshold test: 7470
# points within mask after threshold test: 33     points within mask after threshold test: 7915
# points within mask after threshold test: 331    points within mask after threshold test: 8079
# points within mask after threshold test: 1237   points within mask after threshold test: 7362
# points within mask after threshold test: 1346   points within mask after threshold test: 5972
# points within mask after threshold test: 397    points within mask after threshold test: 3956
# points within mask after threshold test: 105    points within mask after threshold test: 1657
# points within mask after threshold test: 25     points within mask after threshold test: 370
# points within mask after threshold test: 1      points within mask after threshold test: 52
# points within mask after threshold test: 5      points within mask after threshold test: 16
# points within mask after threshold test: 0      points within mask after threshold test: 2
# points within mask after threshold test: 0      points within mask after threshold test: 0
# points within mask after threshold test: 0      points within mask after threshold test: 0

# In the single-look phases case the vast majority of values are in the class 0.0 to 0.1
# For the multi-look phases case < 50% are in this class.
# The reason should not really be atmospheric phase but phase related to
# the non-zero closure phase / inconsistent phase noise (and biases) of the multi-look
# phases.

#pdisdt_pwr24 pt pmask5 ${ref_date}.rslc.par prate 1 ${ref_date}.rmli.par ave.rmli 12.56 3
#pdisdt_pwr24 pt pmask5 ${ref_date}.rslc.par prate 1 ${ref_date}.rmli.par ave.rmli 62.8 3

#     The fast large scale signals are still present as before.
#     Subtracting patm has somewhat reduced the rates in the assumed stable areas
#     but there are still (very noisy) values > 5 radian/year present.

# Based on psigma_ts we can determine a mask that only includes those points
# with psigma_ts values below a certain threshold. We try here several thresholds

/bin/cp pmask5 pmask6
/bin/cp pmask5 pmask6_100
/bin/cp pmask5 pmask6_070
/bin/cp pmask5 pmask6_040
thres_msk_pt pt pmask6_100 psigma_ts 1 0.0 1.0   # --> 135667 points
thres_msk_pt pt pmask6_070 psigma_ts 1 0.0 0.7   # --> 122234 points
thres_msk_pt pt pmask6_040 psigma_ts 1 0.0 0.4   # --> 97277 points

# Display the deformation rate using the different masks:
# pdisdt_pwr pt pmask6_100 20190809.rslc.par prate 1 20190809.rmli.par ave.rmli -31.4 31.4 &
# pdisdt_pwr pt pmask6_070 20190809.rslc.par prate 1 20190809.rmli.par ave.rmli -31.4 31.4 &
# pdisdt_pwr pt pmask6_040 20190809.rslc.par prate 1 20190809.rmli.par ave.rmli -31.4 31.4 &
# pdisdt_pwr pt pmask6_100 20190809.rslc.par prate 1 20190809.rmli.par ave.rmli -6.28 6.28 &
# pdisdt_pwr pt pmask6_070 20190809.rslc.par prate 1 20190809.rmli.par ave.rmli -6.28 6.28 &
# pdisdt_pwr pt pmask6_040 20190809.rslc.par prate 1 20190809.rmli.par ave.rmli -6.28 6.28 &

# with pmask6_100 the result looks extremely noisy in some parts (using 12.6rad/y scale)
# with pmask6_040 the result looks much less noisy (using 12.6rad/y scale) but the coverage
#                 for some of the smaller landslides/rock glaciers is very poor
# using pmask6_070 seems to be a reasonable compromise

# To the elements where unwrapping errors are unlikely we apply now mb_pt
# with a temporal smoothing to get the non-uniform deformation time series.

# we use pmask6_070 for the following steps
/bin/cp pmask6_070 pmask6

# run mb_pt with temporal smoothing
mb_pt pt pmask6 pSLC_par itab pdiff.unw3a 40923 - itab_ts pdiff_ts1 pdiff_sim1 psigma_ts1 1 phgt_out1 1.0 prate1 pconst1 psigma_fit1 ${ref_date}.rslc.par

# convert phase time series to LOS displacement time series
dispmap_pt pt pmask6 pSLC_par itab_ts pdiff_ts1 phgt4 pdisp_ts1 0

#pdisdt_pwr24 pt pmask6 ${ref_date}.rslc.par pdisp_ts1 25 ${ref_date}.rmli.par ave.rmli 0.1 2
# --> up to <<  1 cm effect from atmospheric delays
# --> up to    10 cm effect from deformation

# visualize deformation time series obtained
ras_data_pt pt pmask6 pdisp_ts1 1 25 ave.rmli.bmp ras/pdisp_ts1 2 $rlks $azlks -0.05 0.05
#xv ras/pdisp_ts1_???.bmp &
# bash ../mymontage.sh "ras/pdisp_ts1_???.bmp"

# determine linear LOS deformation rate for this result
base_orbit_pt pSLC_par itab_ts - pbase_ts
spf_pt pt_geo pmask6 ../DEM/EQA.dem_par pdiff_ts1 pdiff_ts1_a - 2 5 0 - $ref_point 0
def_mod_pt pt pmask6 pSLC_par - itab_ts pbase_ts 0 pdiff_ts1_a 0 $ref_point pres pdh pdef punw psigma pmask 100. -0.5 0.5 3.0 5 pdh_err pdef_err
# --> 128440 points

#pdisdt_pwr24 pt pmask6 ${ref_date}.rslc.par pdef 1 ${ref_date}.rmli.par ave.rmli 0.25 2
#pdisdt_pwr24 pt pmask6 ${ref_date}.rslc.par pdef_err 1 ${ref_date}.rmli.par ave.rmli 0.01 2

# The higher pdef_err value observed for the Moosfluh landslide area is related
# to the non-uniform motion (that is not modeled in the linear regression used in def_mod_pt

# In the area with reduced spatial coverage "noisy" values with rates such
# as +5cm/year and -5cm/year are observed, in spite of def_mod_pt indicating
# for these multi-look phases a rate estimation error < 1 cm/year.
pdis2dt_pwr pt pmask6 ${ref_date}.rslc.par pdef 1 pdef_err 1 ${ref_date}.rmli.par - -0.05 0.05

# We understand this as more systematic biases introduced by the non-zero closure phase.

# One possibility to reduce these point-wise outliers is to calculate
# a temporal coherence like measure and use it to threshold the result.

# The phase time series (pdiff_ts1) includes the phase noise.
# To calculate the phase noise we calculate the difference between
# the time series and the spatially filtered time series.

spf_pt pt_geo pmask6 ../DEM/EQA.dem_par pdiff_ts1 pdiff_ts1.spf15 - 2 15 0
lin_comb_pt pt pmask6 pdiff_ts1 - pdiff_ts1.spf15 - pres_ts - 0. 1. -1. 2 0

#pdisdt_pwr24 pt - ${ref_date}.rslc.par pres_ts 10 ${ref_date}.rmli.par ave.rmli -3.14 3.14

# based on pres_ts we determine the temporal coherence (using cct_pt) as a measure for the statistical quality
# of the solution (better suited than psigma and pdef_err for non-uniform spatially smooth deformation history)
cct_pt pt pmask6 ${ref_date}.rslc.par pres_ts pcct 2 0.0 0 15
#pdisdt_pwr24 pt pmask6 ${ref_date}.rslc.par pcct 1 ${ref_date}.rmli.par ave.rmli 1.5 3
# we observe low coherence as a result of phase noise,
# but, unfortunately, also in areas with high deformation rates and gradients.

# we reduce the result to coherence values above a threshold (0.7)
/bin/cp pmask6 pmask_070
thres_msk_pt pt pmask_070 pcct 1 0.70 1.01
# --> 120029 points
# pdisdt_pwr pt pmask_070 20190809.rslc.par pcct 1 20190809.rmli.par ave.rmli 0 1 0 cc.cm

# prasdt_pwr pt pmask_070 20190809.rslc.par pdef 1 20190809.rmli.par ave.rmli -0.15 0.15 0 hls.cm pdef_070.bmp
# prasdt_pwr pt pmask6 20190809.rslc.par pdef 1 20190809.rmli.par ave.rmli -0.15 0.15 0 hls.cm pdef.bmp
# dis2ras pdef_070.bmp pdef.bmp

# --> reduces noise related effects but also reduces spatial coverage in areas with deformation
#     we keep using pmask6 in order to keep the better spatial coverage in areas with deformation

# we reduce the noise, but not in areas with high deformation rates
spf_pt pt_geo pmask6 ../DEM/EQA.dem_par pdef pdef.spf - 2 50 0 15
#pdisdt_pwr24 pt - ${ref_date}.rslc.par pdef.spf 1 ${ref_date}.rmli.par ave.rmli 0.25 3
# --> noisy values in areas with low spatial coverage have no longer a high filtered rate

# pmask6A: fast moving areas
/bin/cp pmask6 pmask6A
thres_msk_pt pt pmask6A pdef.spf 1 -1.0 -0.03
#pdisdt_pwr24 pt pmask6A ${ref_date}.rslc.par pdef 1 ${ref_date}.rmli.par ave.rmli 0.25 3

# add offset to temporal coherence for fast moving areas
lin_comb_pt pt pmask6A pcct - pcct - pcct_offset - 0.999 0. 0. 2 0
lin_comb_pt pt pmask6 pcct - pcct_offset - pcctA - 0.0 1. 1. 2 1
#pdisdt_pwr24 pt pmask6 ${ref_date}.rslc.par pcctA 1 ${ref_date}.rmli.par ave.rmli 1.50 3

# apply coherence threshold again
/bin/cp pmask6 pmask_070A
thres_msk_pt pt pmask_070A pcctA 1 0.70 2.0
# prasdt_pwr pt pmask_070A 20190809.rslc.par pdef 1 20190809.rmli.par ave.rmli -0.15 0.15 0 hls.cm pdef_070A.bmp
# dis2ras pdef_070A.bmp pdef.bmp

# --> 120565 elements

# reduce the estimates in pdef to pmask_070A
lin_comb_pt pt pmask_070A pdef - pdef - pdef_070A - 0.0 1. 0. 2 0

# geocode deformation rate
ras_data_pt pt_geo pmask_070A pdef 1 1 ../DEM/EQA.ave.rmli.bmp pdef_geo 2 1 1 -0.15 0.15 0 hls.cm 3 1
mv pdef_geo_001.bmp ${dem_name}_pdef_geo.bmp
ras2png.py ${dem_name}_pdef_geo.bmp -t
kml_map ${dem_name}_pdef_geo.png ../DEM/EQA.dem_par ${dem_name}.kml

# displaying the time series result
#vu_disp pt pmask_070A pSLC_par itab_ts pdisp_ts1 pdef phgt4 psigma pdh_err pdef_err - pdef_070A.bmp -0.15 0.05 2 128

# --> we very nicely see the Moosfluh landslide as well as several smaller ones!

