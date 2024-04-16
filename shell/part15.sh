#!/bin/bash

# Part 15: Some comparisons and considerations:

work_dir="$1"
ref_date="$2"
rlks="$3"
azlks="$4"
ref_point="$5"
dem_name="$6"

cd ipta

# reduce the estimates in pdef to pmask_070A
lin_comb_pt pt pmask_070A pdef - pdef - pdef_070A - 0.0 1. 0. 2 0

# compare pdef for single pixel and multi-look phases:
lin_comb_pt pt pmask_single pdef_070A 1 pdef_070A 1 pdef_single 1 0. 1. 0. 2 0
lin_comb_pt pt pmask_multilook pdef_070A 1 pdef_070A 1 pdef_multilook 1 0. 1. 0. 2 0
# pdis2dt_pwr pt - 20190809.rslc.par pdef_single 1 pdef_multilook 1 20190809.rmli.par - -0.15 0.15
# pdis2dt_pwr pt - 20190809.rslc.par pdef_single 1 pdef_multilook 1 20190809.rmli.par - -0.05 0.05

# pdis2dt_pwr pt - 20190809.rslc.par pdef_single 1 pdef_multilook 1 20190809.rmli.par ave.rmli -0.15 0.15
# number of displayed points (non-masked, non-zero) from pdef_single: 65688
# number of displayed points (non-masked, non-zero) from pdef_multilook: 49535

# --> area with fast motion is significantly better covered in using the multi-look phases !!!
#     (with the selected multi-looking and threshold used in the processing)
#     But multi-look based result looks somewhat "noisier*, i.e. it shows a stronger high frequency variation
#     than the single-pixel based result - this in spite of the quite strong reduction of the result
#     to spatially consistent (temporally coherent) values.

# compare pdef_err for single pixel and multi-look phases:
lin_comb_pt pt pmask_single pdef_err 1 pdef_err 1 pdef_err_single 1 0. 1. 0. 2 0
lin_comb_pt pt pmask_multilook pdef_err 1 pdef_err 1 pdef_err_multilook 1 0. 1. 0. 2 0
# pdis2dt_pwr pt - 20190809.rslc.par pdef_err_single 1 pdef_err_multilook 1 20190809.rmli.par - 0 0.01

# compare psigma for single pixel and multi-look phases:
lin_comb_pt pt pmask_single psigma 1 psigma 1 psigma_single 1 0. 1. 0. 2 0
lin_comb_pt pt pmask_multilook psigma 1 psigma 1 psigma_multilook 1 0. 1. 0. 2 0
# pdis2dt_pwr pt - 20190809.rslc.par psigma_single 1 psigma_multilook 1 20190809.rmli.par - 0 1.5

