#!/bin/bash

# Test step 11: Preparation and visualization of results

work_dir="$1"
ref_date="$2"
dem_name="$3"

cd ${work_dir}/ipta_test
ref_point_rev=`grep "1" prox_prt.txt | awk -F" " '{print $2}'`
num_row=`cat ../int/bperp_file.txt | wc -l`
echo "number of rows in ../int/bperp_file.txt is ... $num_row"

# generate rasterfile of average rate (in map geometry) for pdefx_spf5 and pdisp1_ratex
# using scale between +- 15cm/year and between +-5cm/year
width=`grep "width" ../DEM/EQA.dem_par | awk -F":" '{print $2}'`
height=`grep "nlines" ../DEM/EQA.dem_par | awk -F":" '{print $2}'`
# single look result, color scale between -15cm/year, 15cm/year:
prasdt_pwr pt_geo pmask_final ../DEM/EQA.dem_par pdisp1_ratex 1 - ../DEM/EQA.ave.rmli.bmp -0.15 0.15 0 hls.cm ${dem_name}.EQA.def.map.bmp 3
#xv Aletsch.EQA.def.map.bmp   # setting color saturation to 1.0

# add red "+" at reference point location
ras_pt pt_geo - ${dem_name}.EQA.def.map.bmp ${dem_name}.EQA.def.map.150.all_singlex.bmp 1 1 255 0 0 15 0 2 $ref_point_rev
# view the rasterfile
#xv Aletsch.EQA.def.map.150.all_singlex.bmp

# single look result, color scale between -5cm/year, 5cm/year:
prasdt_pwr pt_geo pmask_final ../DEM/EQA.dem_par pdisp1_ratex 1 - ../DEM/EQA.ave.rmli.bmp -0.05 0.05 0 hls.cm ${dem_name}.EQA.def.map.bmp 3
#xv Aletsch.EQA.def.map.bmp   # setting color saturation to 1.0

# add red "+" at reference point location
ras_pt pt_geo - ${dem_name}.EQA.def.map.bmp ${dem_name}.EQA.def.map.050.all_singlex.bmp 1 1 255 0 0 15 0 2 $ref_point_rev
# view the rasterfile
#xv Aletsch.EQA.def.map.050.all_singlex.bmp

# spatially filtered result, color scale between -15cm/year, 15cm/year:
prasdt_pwr pt_geo pmask_final_spf ../DEM/EQA.dem_par pdefx_spf5 1 - ../DEM/EQA.ave.rmli.bmp -0.15 0.15 0 hls.cm ${dem_name}.EQA.def.map.bmp 3
#xv Aletsch.EQA.def.map.bmp   # setting color saturation to 1.0

# add red "+" at reference point location
ras_pt pt_geo - ${dem_name}.EQA.def.map.bmp ${dem_name}.EQA.def.map.150.all_singlex_spf.bmp 1 1 255 0 0 15 0 2 $ref_point_rev
# view the rasterfile
#xv Aletsch.EQA.def.map.150.all_singlex_spf.bmp

# spatially filtered result, color scale between -5cm/year, 5cm/year:
prasdt_pwr pt_geo pmask_final_spf ../DEM/EQA.dem_par pdefx_spf5 1 - ../DEM/EQA.ave.rmli.bmp -0.05 0.05 0 hls.cm ${dem_name}.EQA.def.map.bmp 3
#xv Aletsch.EQA.def.map.bmp   # setting color saturation to 1.0

# add red "+" at reference point location
ras_pt pt_geo - ${dem_name}.EQA.def.map.bmp ${dem_name}.EQA.def.map.050.all_singlex_spf.bmp 1 1 255 0 0 15 0 2 $ref_point_rev
# view the rasterfile
#xv Aletsch.EQA.def.map.050.all_singlex_spf.bmp

# -->
# Aletsch.EQA.def.map.050.all_singlex.bmp
# Aletsch.EQA.def.map.050.all_singlex_spf.bmp
# Aletsch.EQA.def.map.150.all_singlex.bmp
# Aletsch.EQA.def.map.150.all_singlex_spf.bmp

dis2ras ${dem_name}.EQA.def.map.050.all_singlex_spf.bmp ${dem_name}.EQA.def.map.050.all_singlex.bmp

# get color scales
vis_colormap_bar.py hls.cm ${dem_name}.def.color_scale_050.png -5. 5. -l 'LOS displacement rate in cm/year' -m
vis_colormap_bar.py hls.cm ${dem_name}.def.color_scale_150.png -15. 15. -l 'LOS displacement rate in cm/year' -m

##############################

# visualize time series using vu_disp

vu_disp pt_geo pmask_final pSLC_par itab_ts pdisp1_tsx pdisp1_ratex phgt4 psigmax pdh_errx pdef_errx - ${dem_name}.EQA.def.map.050.all_singlex.bmp -0.12 0.04 2 128

vu_disp pt_geo pmask_final_spf pSLC_par itab_ts pdisp1.tsx_spf5 pdefx_spf5 phgt4 psigmax_spf5 pdh_errx_spf5 pdef_errx_spf5 - ${dem_name}.EQA.def.map.050.all_singlex_spf.bmp -0.12 0.04 2 128

##############################

# generate ASCII files of the results using disp_prt:

# for single-look pixels (without spatial filtering)
disp_prt pt_geo pmask_final - pSLC_par itab_ts plat_lon phgt4 pdisp1_ratex pcctx pdh_errx pdef_errx pdisp1_tsx $ref_point_rev ${dem_name}.all_single_look.EQA.items.txt ${dem_name}.all_single_look.EQA.disp_tab.txt

# for single-look pixels (with spatial filtering)
disp_prt pt_geo pmask_final_spf - pSLC_par itab_ts plat_lon phgt4 pdefx_spf5 pcctx_spf5 pdh_errx_spf5 pdef_errx_spf5 pdisp1.tsx_spf5 $ref_point_rev ${dem_name}.all_single_look_spf.EQA.items.txt ${dem_name}.all_single_look_spf.EQA.disp_tab.txt

# -->
# Aletsch.all_single_look.EQA.disp_tab.txt
# Aletsch.all_single_look_spf.EQA.disp_tab.txt

