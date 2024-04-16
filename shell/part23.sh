#!/bin/bash

# Test step 7: Phase interpretation and generation of time-series

work_dir="$1"
ref_date="$2"
rlks="$3"
azlks="$4"

cd ${work_dir}/ipta_test
ref_point_rev=`grep "1" prox_prt.txt | awk -F" " '{print $2}'`
num_row=`cat ../int/bperp_file.txt | wc -l`
echo "number of rows in ../int/bperp_file.txt is ... $num_row"

# In the following the unwrapped phases are converted into a deformation time series and
# atmospheric phases; this is done using the following assumption:

# Approach:
# - patm_mod is estimated based on the unwrapped phases of the multi-reference pairs
# - patm is estimated based on multi-reference pairs
#   - it is assumed that the atmospheric phase is spatially smooth
#   - it is assumed that the deformation is either fast (e.g. > 10.0 radian/year)
#     or local (for the areas with fast or local deformation non-uniform motion is retrieved)
# - areas with either fast or local deformation (e.g. difference from spatial average > 1.0 radian/year)
#   are masked from the patm estimation to avoid mitigating deformation phase into patm
# - based on the linear deformation rate over the entire period the
#   area that has no strong deformation nor local deformation is determined.
#   Based on this area, the atmospheric phase patm is estimated individually
#   per multi-reference stack layer and subtracted.
# - For this short total observation interval (e.g. 5 months S1 data) this
#   reduces the atmospheric effects on the linear deformation rate and
#   on the deformatioin time series significantly - on the other hand
#   spatially smooth slow deformation is potentially not included in the result
#   (but shifted into the atmospheric phase)

# The atmospheric path delay phase is individually estimated for each pair
# of the multi-reference stack. To constrain the estimation of the atmospheric
# path delays to "almost stable" areas, we need to generate a mask.

################################

# generate mask pmask_slow (to exclude fast or local deformation from the atm phase estimation)

# strategy to generate mask for patm estimation
# - use previous patm_mod and patm estimates (patm_mod, patm3)
# - run mb_pt without smoothing to get phase rate (prate_tmp2a)
# - determine pdrate (local deviation from spatially filtered rate)
# - generate mask based on prate and pdrate

# cp pdiff.unw2.corrected to pdiff.unw3
/bin/cp pdiff.unw2.corrected pdiff.unw3

# create model of atmospheric phase and subtract it
if [ -e ptmp1 -o ptmp2 ];then /bin/rm ptmp1 ptmp2; fi
sub_phase_pt pt pmask_consistent pdiff.unw3 - patm_mod ptmp1 0 0
sub_phase_pt pt pmask_consistent ptmp1 - patm3 ptmp2 0 0

# subtract reference point phase from each layer:
# and run mb_pt without temporal smoothing to get an estimate of the average deformation rate
spf_pt pt_geo pmask_consistent ../DEM/EQA.dem_par ptmp2 ptmp2a - 2 5 0 - $ref_point_rev 1
mb_pt pt pmask_consistent pSLC_par itab ptmp2a $ref_point_rev - itab_ts pdiff_ts_tmp2a pdiff_sim_tmp2a psigma_ts_tmp2a 1 phgt_out_tmp2a 0.0 prate_tmp2a pconst_tmp2a psigma_fit_tmp2a ${ref_date}.rslc.par

#pdisdt_pwr24 pt pmask_consistent ${ref_date}.rslc.par prate_tmp2a 1 ${ref_date}.rmli.par ave.rmli 62.8 3
#pdisdt_pwr24 pt pmask_consistent ${ref_date}.rslc.par psigma_ts_tmp2a 1 ${ref_date}.rmli.par ave.rmli 3.0 3
#pdisdt_pwr24 pt pmask_consistent ${ref_date}.rslc.par psigma_fit_tmp2a 1 ${ref_date}.rmli.par ave.rmli 3.0 3

#  apply psigma_ts_tmp2a threshold
/bin/cp pmask_consistent pmask_low_psigma_ts_tmp2a
thres_msk_pt pt pmask_low_psigma_ts_tmp2a psigma_ts_tmp2a 1 0.0 0.5     # --> 2268797 points

# determine local relative phase rate pdrate_tmp2a
fspf_pt pt_geo pmask_low_psigma_ts_tmp2a ../DEM/EQA.dem_par prate_tmp2a prate_spf35 - 2 35 0
sub_phase_pt pt pmask_low_psigma_ts_tmp2a prate_tmp2a 1 prate_spf35 pdrate_tmp2a 0 0
#pdisdt_pwr24 pt pmask_low_psigma_ts_tmp2a ${ref_date}.rslc.par pdrate_tmp2a 1 ${ref_date}.rmli.par ave.rmli 16.8 3

# To estimate atmospheric phases determine a mask pmask_slow to exclude:
# a) large fast moving areas
# b) areas that show a significantly different motion than its neighborhood (local phenomena)

#  apply slight spatial filtering to avoid too much noise
spf_pt pt_geo pmask_low_psigma_ts_tmp2a ../DEM/EQA.dem_par prate_tmp2a prate_tmp2a_spf5 - 2 5 1
#pdisdt_pwr24 pt pmask_low_psigma_ts_tmp2a ${ref_date}.rslc.par prate_tmp2a_spf5 1 ${ref_date}.rmli.par ave.rmli 62.8 3

/bin/cp pmask_low_psigma_ts_tmp2a pmask_fast
thres_msk_pt pt pmask_fast prate_tmp2a_spf5 1 12.0 10000.0      # --> 24703 points
#pdisdt_pwr24 pt pmask_fast ${ref_date}.rslc.par prate_tmp2a_spf5 1 ${ref_date}.rmli.par ave.rmli 62.8 3

# slightly expand area around fast moving landslides
lin_comb_pt pt pmask_fast prate_tmp2a_spf5 - prate_tmp2a_spf5 - prate_tmp_fast1 - 0.0 1. 0. 2 0
lin_comb_pt pt pmask_low_psigma_ts_tmp2a prate_tmp_fast1 - prate_tmp_fast1 - prate_tmp_fast2 - 0.00001 1. 0. 2 1
#pdisdt_pwr24 pt pmask_low_psigma_ts_tmp2a ${ref_date}.rslc.par prate_tmp_fast2 1 ${ref_date}.rmli.par ave.rmli 62.8 3

fspf_pt pt_geo pmask_low_psigma_ts_tmp2a ../DEM/EQA.dem_par prate_tmp_fast2 prate_tmp_fast2_spf35 - 2 35 1 1
#pdisdt_pwr24 pt pmask_low_psigma_ts_tmp2a ${ref_date}.rslc.par prate_tmp_fast2_spf35 1 ${ref_date}.rmli.par ave.rmli 62.8 3

/bin/cp pmask_low_psigma_ts_tmp2a pmask_slow
thres_msk_pt pt pmask_slow prate_tmp_fast2_spf35 1 -2.0 2.0     # --> 2216453 points
#pdisdt_pwr24 pt pmask_slow ${ref_date}.rslc.par prate_tmp2a 1 ${ref_date}.rmli.par ave.rmli 62.8 3

thres_msk_pt pt pmask_slow pdrate_tmp2a 1 -1.0 1.0              # --> 534601 points
#pdisdt_pwr24 pt pmask_slow ${ref_date}.rslc.par prate_tmp2a 1 ${ref_date}.rmli.par ave.rmli 62.8 3

# --> pmask_slow  (to be used in estimation of patm_mod and patm phases in multi-reference stack)

################################

# estimate patm_mod and patm for multi-reference stack upwrapped phases (pdiff.unw3)
# considering only the areas without deformation (pmask_slow)

# estimate patm_mod4 (per multi-reference stack layer)
atm_mod_pt pt pmask_slow pdiff.unw3 phgt3 patm_mod4

# estimate patm4 (per multi-reference stack layer)
/bin/rm ptmp1 ptmp2
sub_phase_pt pt pmask_slow pdiff.unw3 - patm_mod4 ptmp1 0 0
fspf_pt pt_geo pmask_slow ../DEM/EQA.dem_par ptmp1 ptmp2 - 2 50 1 1
expand_data_inpaint_pt pt_geo pmask_slow ../DEM/EQA.dem_par ptmp2 pt_geo - patm4 - 0 10 4 - 0
ras_data_pt pt - patm4 1 $num_row ave.rmli.bmp ras/patm4 2 $rlks $azlks -6.28 6.28 1 rmg.cm
#xv -exp -2 ras/patm4_???.bmp &
bash ../mymontage.sh "ras/patm4_???.bmp"

# --> patm_mod4, patm4

################################

# estimate a height correction (using mb_pt) and related phase corrections

# subtract patm_mod4, patm4 from pdiff.unw3 an estimate height correction
# by running mb_pt with a temporal smoothing
/bin/rm ptmp1 ptmp2
sub_phase_pt pt pmask_low_psigma_ts_tmp2a pdiff.unw3 - patm_mod4 ptmp1 0 0
sub_phase_pt pt pmask_low_psigma_ts_tmp2a ptmp1 - patm4 pdiff1.unw3 0 0
mb_pt pt pmask_low_psigma_ts_tmp2a pSLC_par itab pdiff1.unw3 $ref_point_rev - itab_ts pdiff1.tsx pdiff1_simx psigma_tsx 1 pdh_outx 1.0 pratex pconstx psigma_fitx ${ref_date}.rslc.par

#pdisdt_pwr24 pt - ${ref_date}.rslc.par pdh_outx 1 ${ref_date}.rmli.par ave.rmli 100. 3

# update heights; we separate a low and a high frequency part of the correction
fspf_pt pt_geo - ../DEM/EQA.dem_par pdh_outx pdh_outx.spf - 2 150 0
#pdisdt_pwr24 pt - ${ref_date}.rslc.par pdh_outx.spf 1 ${ref_date}.rmli.par ave.rmli 100. 3
lin_comb_pt pt pmask_low_psigma_ts_tmp2a pdh_outx 1 pdh_outx.spf 1 pdh_outx.hf - 0.0 1. -1. 2 0
#pdisdt_pwr24 pt - ${ref_date}.rslc.par pdh_outx.hf 1 ${ref_date}.rmli.par ave.rmli 100. 3

# --> the height correction has a low frequency part pdh_outx.spf and a high frequency part pdh_outx.hf
#     We use the high frequency part to update the terrain heights (phgt4 = phgt3 + pdh_outx.hf)
#     We estimate the phase effect for the height correction and subtract it then from the differential interferograms.
#     We shift the phase corresponding to the low frequency part into the atmospheric
#     phase (so that we don't get this correction again in a next iteration).

lin_comb_pt pt - phgt3 1 pdh_outx.hf 1 phgt4 1 0.0 1. 1. 2 1
#pdisdt_pwr24 pt - ${ref_date}.rslc.par phgt4 1 ${ref_date}.rmli.par ave.rmli 200. 3

# simulate the phase corresponding to the height correction phgt_outx.hf and subtract it from the differential interferograms
phase_sim_pt pt pmask_low_psigma_ts_tmp2a pSLC_par - itab - pbase pdh_outx.hf pdh_outx.hf.sim_unw - 2 0
ras_data_pt pt_geo - pdh_outx.hf.sim_unw 1 $num_row ../DEM/EQA.ave.rmli.bmp ras/pdh_outx.hf.sim_unw 2 1 1 -6.28 6.28 1 rmg.cm
#xv -exp -4 ras/pdh_outx.hf.sim_unw_???.bmp &    # the main effect is visible at the edges of the glaciers
bash ../mymontage.sh "ras/pdh_outx.hf.sim_unw_???.bmp"

# simulate the phase corresponding to the low frequency part of the height correction phgt_outx.spf and add it to the patm4
phase_sim_pt pt - pSLC_par - itab - pbase pdh_outx.spf pdh_outx.spf.sim_unw - 2 0
ras_data_pt pt_geo - pdh_outx.spf.sim_unw 1 $num_row ../DEM/EQA.ave.rmli.bmp ras/pdh_outx.spf.sim_unw 2 1 1 -6.28 6.28 1 rmg.cm
#xv -exp -4 ras/pdh_outx.spf.sim_unw_???.bmp &
bash ../mymontage.sh "ras/pdh_outx.spf.sim_unw_???.bmp"

cp patm4 patm4.0
lin_comb_pt pt - patm4.0 - pdh_outx.spf.sim_unw - patm4 - 0.0 1. 1. 2 0

# we display the atmospheric phase patm4 (after patm_mod1 was subtracted)
ras_data_pt pt_geo - patm4 1 $num_row ../DEM/EQA.ave.rmli.bmp ras/patm4 2 1 1 -6.28 6.28 1 rmg.cm
#xv -exp -4 ras/patm4_???.bmp &
bash ../mymontage.sh "ras/patm4_???.bmp"

# --> pdh_outx.hf, pdh_outx.hf.sim_unw, phgt4
# --> patm4 has been updated

###########################

# apply mb_pt without temporal smoothing (to get non-uniform time series, incl. noise)

# subtract updated atmospheric path delay and height correction related phase from pdiff.unw3
# to get pdiff1.unw3 (as mask use pmask_low_psigma_ts_tmp2a)
/bin/rm ptmp1 ptmp2
sub_phase_pt pt pmask_low_psigma_ts_tmp2a pdiff.unw3 - patm_mod4 ptmp1 0 0
sub_phase_pt pt pmask_low_psigma_ts_tmp2a ptmp1 - pdh_outx.hf.sim_unw ptmp2 0 0
sub_phase_pt pt pmask_low_psigma_ts_tmp2a ptmp2 - patm4 pdiff1.unw3 0 0

# subtract reference point phase from each layer:
spf_pt pt_geo pmask_low_psigma_ts_tmp2a ../DEM/EQA.dem_par pdiff1.unw3 pdiff1.unw3a - 2 15 0 - $ref_point_rev 1

# apply mb_pt without temporal smoothing (to get non-uniform time series, incl. noise)
mb_pt pt pmask_low_psigma_ts_tmp2a pSLC_par itab pdiff1.unw3a $ref_point_rev - itab_ts pdiff1.tsx pdiff1_simx psigma_tsx 1 pdh_outx 0.0 pratex pconstx psigma_fitx ${ref_date}.rslc.par

#pdisdt_pwr24 pt - ${ref_date}.rslc.par pratex 1 ${ref_date}.rmli.par ave.rmli 12.56 3
#pdisdt_pwr24 pt - ${ref_date}.rslc.par pratex 1 ${ref_date}.rmli.par ave.rmli 62.8 3
#     The fast large scale signals are still present as before.
#     Subtracting patm has reduced the rates in the assumed stable areas to < 5 radian/year.
#     but values are still substantial and very noisy.

#pdisdt_pwr24 pt - ${ref_date}.rslc.par psigma_tsx 1 ${ref_date}.rmli.par ave.rmli 3.0 3
# psigma_tsx values are all small (unwrapping is consistent for these points)

# --> phase time series pdiff1.tsx (and linear rate pratex)

###########################

# quality control / determine temporal coherence and a mask for the accepted quality (--> pmask_050x)

# as a noise measure we determine the difference between the (temporally unfiltered) phase time series and
# the spatially filtered phase time series (--> pres4)

spf_pt pt_geo pmask_low_psigma_ts_tmp2a ../DEM/EQA.dem_par pdiff1.tsx pdiff1.tsx.spf15 - 2 15 0
lin_comb_pt pt pmask_low_psigma_ts_tmp2a pdiff1.tsx - pdiff1.tsx.spf15 - pres4 - 0. 1. -1. 2 0

#pdisdt_pwr24 pt - ${ref_date}.rslc.par pres4 10 ${ref_date}.rmli.par ave.rmli 6.28 3

# using pres4 we determine two "temporal coherence" values B (using cct_pt without phase bias removal)
# and pcct4A (using cct_pt without phase bias removal using a radius 35), as measures for
# the statistical quality of the solution (pmask_low_psigma_ts_tmp2a pdiff1.tsx).
# (pcct4A and pcct4B are better suited as quality measure than psigma and pdef_err for non-uniform
#  spatially smooth deformation histories)
cct_pt pt pmask_low_psigma_ts_tmp2a ${ref_date}.rslc.par pres4 pcct4A 2  0.0 0 5
cct_pt pt pmask_low_psigma_ts_tmp2a ${ref_date}.rslc.par pres4 pcct4B 2 35.0 0 5
#pdis2dt pt pmask_low_psigma_ts_tmp2a ${ref_date}.rslc.par pcct4A 1 pcct4B 1 ${ref_date}.rmli.par 1.5 0

# values vary significantly; values are low because of noise, but also because of high gradients

/bin/cp pmask_low_psigma_ts_tmp2a pmask_tmp; thres_msk_pt pt pmask_tmp pcct4A 1 0.3   1.01  #    2169092 points
/bin/cp pmask_low_psigma_ts_tmp2a pmask_tmp; thres_msk_pt pt pmask_tmp pcct4A 1 0.5   1.01  #    1846950 points
/bin/cp pmask_low_psigma_ts_tmp2a pmask_tmp; thres_msk_pt pt pmask_tmp pcct4A 1 0.7   1.01  #     992156 points
/bin/cp pmask_low_psigma_ts_tmp2a pmask_tmp; thres_msk_pt pt pmask_tmp pcct4B 1 0.3   1.01  #    2143985 points
/bin/cp pmask_low_psigma_ts_tmp2a pmask_tmp; thres_msk_pt pt pmask_tmp pcct4B 1 0.5   1.01  #    1785748 points
/bin/cp pmask_low_psigma_ts_tmp2a pmask_tmp; thres_msk_pt pt pmask_tmp pcct4B 1 0.7   1.01  #     904412 points
/bin/cp pmask_low_psigma_ts_tmp2a pmask_tmp; thres_msk_pt pt pmask_tmp pcct4B 1 0.4   1.01  #    2018438 points

/bin/cp pmask_low_psigma_ts_tmp2a pmask_050
thres_msk_pt pt pmask_050 pcct4A 1 0.45   1.01                  # 1979057 points
thres_msk_pt pt pmask_050 pcct4B 1 0.35   1.01                  # 1889155 points

#pdisdt_pwr24 pt pmask_050 ${ref_date}.rslc.par pratex 1 ${ref_date}.rmli.par ave.rmli 62.8 3
#pdisdt_pwr24 pt pmask_low_psigma_ts_tmp2a ${ref_date}.rslc.par pratex 1 ${ref_date}.rmli.par ave.rmli 62.8 3

# a coherence measure tends to also mask parts of the fast moving areas with high spatial gradients
# as this is very relevant information we try to avoid masking such areas

# do not mask very fast areas
/bin/cp pmask_low_psigma_ts_tmp2a pmask_fast1
spf_pt pt_geo pmask_low_psigma_ts_tmp2a ../DEM/EQA.dem_par pratex pratex.spf5 - 2 25 0 9 # maximum radius: 9
#pdisdt_pwr24 pt pmask_low_psigma_ts_tmp2a ${ref_date}.rslc.par pratex.spf5 1 ${ref_date}.rmli.par ave.rmli 62.8 3
/bin/cp pmask_low_psigma_ts_tmp2a pmask_fast1
thres_msk_pt pt pmask_fast1 pratex.spf5 1 15. 1000.                     # 18855 points
#pdisdt_pwr24 pt pmask_fast1 ${ref_date}.rslc.par pratex 1 ${ref_date}.rmli.par ave.rmli 62.8 3

# --> areas with deformation but also some isolated potential outliers
# To remove the outliers we add the condition of a minimum point density
pt_density pt pmask_fast1 ${ref_date}.rslc.par pdens_mask_fast1 25
#pdisdt_pwr24 pt pmask_fast1 ${ref_date}.rslc.par pdens_mask_fast1 1 ${ref_date}.rmli.par ave.rmli 100.0 3
thres_msk_pt pt pmask_fast1 pdens_mask_fast1 1 8. 10000.                # 17950 points
#pdisdt_pwr24 pt pmask_fast1 ${ref_date}.rslc.par pratex 1 ${ref_date}.rmli.par ave.rmli 62.8 3

# combine pmask_fast1 and pmask_050 (to avoid masking relevant information)
/bin/rm ptmp1 ptmp2 ptmp3 pmask_050x
lin_comb_pt pt pmask_fast1 pratex - pratex - ptmp1 - 10. 0. 0. 2 0
lin_comb_pt pt pmask_050   pratex - pratex - ptmp2 - 10. 0. 0. 2 0
lin_comb_pt pt -  ptmp2 - ptmp1 - ptmp3 - 0. 1. 1. 2 1
/bin/cp pmask_low_psigma_ts_tmp2a pmask_050x
thres_msk_pt pt pmask_050x ptmp3 1 5 25                 # 1893327 points

#pdisdt_pwr24 pt pmask_050x ${ref_date}.rslc.par pratex 1 ${ref_date}.rmli.par ave.rmli 62.8 1
#pdisdt_pwr24 pt - ${ref_date}.rslc.par pratex 1 ${ref_date}.rmli.par ave.rmli 62.8 1

# --> pmask_050x

###########################

# We have now the phase time series (including noise) for the single-look values
# available (pdiff1.tsx) and a related mask (pmask_050x).

# Based on pdiff1.tsx and pmask_050x we generate now two solutions:
# 1. the single look time series result
# 2. the spatially filtered result

