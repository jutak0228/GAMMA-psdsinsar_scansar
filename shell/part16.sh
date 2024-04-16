#!/bin/bash

# Part 16: Results:

work_dir="$1"
ref_date="$2"
rlks="$3"
azlks="$4"
ref_point="$5"
dem_name="$6"

cd ipta

num_row=`cat ../int/bperp_file.txt | wc -l`
echo "number of rows in ../int/bperp_file.txt is ... $num_row"

<< check_results
pdem_combined                   # dem heights
phgt4                           # corrected heights
pdh4.total                      # height correction
pdh4.sim_unw                    # phase correspdonding to height correction

patm_mod                        # height dependent atmopsheric path delay phase (for multi-ref stack)
patm                            # atmospheric path delay phase (after subtracting patm_mod, for multi-ref stack)

pdiff_ts1, pdisp_ts1            # phase and LOS displacement time series
pdef                            # linear deformation rate estimated from phase time series using def_mod_pt
pdef_err                        # pdef estimation error (includes effects of non-uniform def phase)

pres                            # phase deviation from linear regression (includes non-uniform def phase)
psigma                          # stdev of phase deviation from linear regression (includes effects from non-uniform def phase)
psigma_ts1                      # stdev of phases from smoothed non-uniform time series
pres_ts                         # noise part of phase time series
pcct                            # temporal coherence estimated based on noise part of phase time series

pmask6                          # pmask obtained with a phase standard deviation of 0.7 rad in mb_pt
pmask6_040                      # pmask obtained with a phase standard deviation of 0.4 rad in mb_pt
pmask6_100                      # pmask obtained with a phase standard deviation of 1.0 rad in mb_pt
pmask_070                       # pmask using a coherence threshold of 0.70
pmask_070A                      # pmask using a coherence threshold of 0.70 (but without reducing coverage in fast moving areas)
pmask_single                    # pmask for all single-look elements
pmask_multilook                 # pmask for all multi-look elements

pt_geo                          # point list with map pixel numbers
plat_lon                        # geographic coordinates of elements
check_results

# check map pixel numbers at reference point (41061)
prt_pt pt - pt_geo $ref_point 1 8 -
# -->        1    41061   3127    761   1824   1218

# check map coordinates at reference point (41061)
prt_pt pt - plat_lon $ref_point 1 7 -
# -->        1    41061   3127    761       8.06664897      46.39169565

# generate color scale for deformation map visualization
vis_colormap_bar.py hls.cm pdef_final.colors.150.png -0.15 0.15 -l "LOS deformation [m/year]"
vis_colormap_bar.py hls.cm pdef_final.colors.050.png -0.05 0.05 -l "LOS deformation [m/year]"
vis_colormap_bar.py hls.cm pdef_final.colors.200.png -0.2 0.2 -l "LOS deformation [m/year]"
#xv pdef_final.colors.???.png &
# bash ../mymontage.sh "pdef_final.colors.???.png"

# generate geocoded map of deformation rates (using non-cyclic color scale)

# scale between -0.15 0.15 m/year, points drawn at maximum intensity
prasdt_pwr pt_geo pmask_070A ../DEM/EQA.dem_par pdef 1 - ../DEM/EQA.ave.rmli.bmp -0.15 0.15 0 hls.cm ${dem_name}.EQA.def.map.bmp 3
# add red "+" at reference point location
ras_pt pt_geo - ${dem_name}.EQA.def.map.bmp ${dem_name}.EQA.def.map.150.bmp 1 1 255 0 0 15 0 2 $ref_point
# view the rasterfile
#xv Aletsch.EQA.def.map.150.bmp
# or disras_dem_par Aletsch.EQA.def.map.150.bmp ../DEM/EQA.dem_par
# for comparison see also results/Aletsch.EQA.def.map.150.jpg

# scale between -0.05 0.05 m/year
prasdt_pwr pt_geo pmask_070A ../DEM/EQA.dem_par pdef 1 - ../DEM/EQA.ave.rmli.bmp -0.05 0.05 0 hls.cm ${dem_name}.EQA.def.map.bmp 3
# add red "+" at reference point location
ras_pt pt_geo - ${dem_name}.EQA.def.map.bmp ${dem_name}.EQA.def.map.050.bmp 1 1 255 0 0 15 0 2 $ref_point
# view the rasterfile
#xv Aletsch.EQA.def.map.050.bmp
# or disras_dem_par Aletsch.EQA.def.map.050.bmp ../DEM/EQA.dem_par
# for comparison see also results/Aletsch.EQA.def.map.050.jpg

# scale between -0.15 0.15 m/year
width=`grep "width" ../DEM/EQA.dem_par | awk -F":" '{print $2}'`
height=`grep "nlines" ../DEM/EQA.dem_par | awk -F":" '{print $2}'`

##############################

# display time series, and other terms (pdef_final phgt1 pcct pdh_err pdef_err)
# using the interactive IPTA visualization tool vu_disp

vu_disp pt_geo pmask_070A pSLC_par itab_ts pdisp_ts1 pdef phgt4 pcct pdh_err4 pdef_err plat_lon ${dem_name}.EQA.def.map.150.bmp -0.15 0.05 &

# or alternatively

vu_disp pt_geo pmask_070A pSLC_par itab_ts pdisp_ts1 pdef phgt4 pcct pdh_err4 pdef_err plat_lon ${dem_name}.EQA.def.map.050.bmp -0.15 0.05 &

##############################

# generate ASCII files of the results using disp_prt:

disp_prt pt_geo pmask_070A - pSLC_par itab_ts plat_lon phgt4 pdef pcct pdh_err pdef_err pdisp_ts1 $ref_point ${dem_name}.EQA.items.txt ${dem_name}.EQA.disp_tab.txt
#e Aletsch.EQA.items.txt
#e Aletsch.EQA.disp_tab.txt
gzip -c ${dem_name}.EQA.disp_tab.txt > ${dem_name}.EQA.disp_tab.txt.gz
# --> comma separated value file can be used for importing into Excel sheets or GIS

##############################

# visualize final atmospheric phases patm, patm_mod:

ras_data_pt pt_geo pmask_070A patm 1 $num_row ../DEM/EQA.ave.rmli.bmp ras/patm 2 1 1 -3.14159 3.14159 1 rmg.cm 3
#xv -exp -2 ras/patm_???.bmp &
# bash ../mymontage.sh "ras/patm_???.bmp"

# dimension is 3085x2341, we rescale to 1/8 and generate mosaics using montage (ImageMagick)
res_w=$((width/8/2))
res_h=$((height/8/2))
montage -geometry +2+2 -resize ${res_w}x${res_h} ras/patm_00?.bmp ${dem_name}.patm.01to09.jpg
montage -geometry +2+2 -resize ${res_w}x${res_h} ras/patm_01?.bmp ${dem_name}.patm.10to19.jpg
montage -geometry +2+2 -resize ${res_w}x${res_h} ras/patm_02?.bmp ${dem_name}.patm.20to29.jpg
montage -geometry +2+2 -resize ${res_w}x${res_h} ras/patm_03?.bmp ${dem_name}.patm.30to39.jpg
montage -geometry +2+2 -resize ${res_w}x${res_h} ras/patm_04?.bmp ${dem_name}.patm.40to49.jpg
montage -geometry +2+2 -resize ${res_w}x${res_h} ras/patm_05?.bmp ${dem_name}.patm.50to59.jpg
montage -geometry +2+2 -resize ${res_w}x${res_h} ras/patm_06?.bmp ${dem_name}.patm.60to66.jpg
#xv Aletsch.patm.??to??.jpg
# bash ../mymontage.sh "${dem_name}.patm.??_??.jpg"

ras_data_pt pt_geo pmask_070A patm_mod 1 $num_row ../DEM/EQA.ave.rmli.bmp ras/patm_mod 2 1 1 -3.14159 3.14159 1 rmg.cm 3
#xv -exp -2 ras/patm_mod_???.bmp &
# bash ../mymontage.sh "ras/patm_mod_???.bmp"

montage -geometry +2+2 -resize ${res_w}x${res_h} ras/patm_mod_00?.bmp ${dem_name}.patm_mod.01to09.jpg
montage -geometry +2+2 -resize ${res_w}x${res_h} ras/patm_mod_01?.bmp ${dem_name}.patm_mod.10to19.jpg
montage -geometry +2+2 -resize ${res_w}x${res_h} ras/patm_mod_02?.bmp ${dem_name}.patm_mod.20to29.jpg
montage -geometry +2+2 -resize ${res_w}x${res_h} ras/patm_mod_03?.bmp ${dem_name}.patm_mod.30to39.jpg
montage -geometry +2+2 -resize ${res_w}x${res_h} ras/patm_mod_04?.bmp ${dem_name}.patm_mod.40to49.jpg
montage -geometry +2+2 -resize ${res_w}x${res_h} ras/patm_mod_05?.bmp ${dem_name}.patm_mod.50to59.jpg
montage -geometry +2+2 -resize ${res_w}x${res_h} ras/patm_mod_06?.bmp ${dem_name}.patm_mod.60to66.jpg
#xv Aletsch.patm_mod.??to??.jpg
# bash ../mymontage.sh "${dem_name}.patm_mod.??_??.jpg"

##############################

# generate geotiff of the backscattering and the deformation rate:

data2geotiff ../DEM/EQA.dem_par ../DEM/EQA.ave.rmli.bmp 0 ${dem_name}.EQA.ave.rmli.tif ${dem_name}.tif.meta
data2geotiff ../DEM/EQA.dem_par ${dem_name}.EQA.def.map.150.bmp 0 ${dem_name}.EQA.def.map.150.tif ${dem_name}.tif.meta
data2geotiff ../DEM/EQA.dem_par ${dem_name}.EQA.def.map.050.bmp 0 ${dem_name}.EQA.def.map.050.tif ${dem_name}.tif.meta

# visualization e.g. using gimp and checking of geotiff file:
#gimp ${dem_name}.EQA.def.map.150.tif
#gdalinfo ${dem_name}.EQA.def.map.150.tif
#listgeo ${dem_name}.EQA.def.map.150.tif
#tiffinfo ${dem_name}.EQA.def.map.150.tif

# for comparison see also results/

##############################

# generate KMZ file for Google Earth for individual points
kml_ts_pt pt pmask_070A pSLC_par itab_ts pdisp_ts1 pdef phgt4 psigma pdh_err pdef_err pcct plat_lon ${dem_name}.EQA.disp_150.kmz ${dem_name} - -0.15 0.15 0 hls.cm - - - - $ref_point - - gamma

# --> kmz file Aletsch.EQA.disp_150.kmz
# can be visualized using Google Earth
# for comparison see results/Aletsch.EQA.disp_150.kmz

##############################

# to generate kml for a smaller section of the area of interest (e.g. Moosfluh landslide area)
echo "Create and generate kml for a smaller section of the area of interest..."
polyras ${dem_name}.EQA.def.map.050.bmp > poly.target
poly_math ../DEM/EQA.ave.rmli EQA.poly.target $width poly.target - 1 10.0 0.0
d2pt EQA.poly.target $width pt_geo 1 1 pEQA.poly.target 1 2
/bin/cp pmask_070A pmask_070A_target
thres_msk_pt pt_geo pmask_070A_target pEQA.poly.target 1 9.9 10.1
# 10573

# scale between -0.20 0.20 m/year
# prasdt_pwr pt_geo pmask_070A_target ../DEM/EQA.dem_par pdef 1 - ../DEM/EQA.ave.rmli.bmp -0.2 0.2 0 hls.cm ${dem_name}.EQA.def.map.bmp 3
# add red "+" at reference point location
ras_pt pt_geo - ${dem_name}.EQA.def.map.bmp target.EQA.def.map.200.bmp 1 1 255 0 0 15 0 2 $ref_point
# view the rasterfile
#xv Moosfluh.EQA.def.map.200.bmp
# or disras_dem_par Moosfluh.EQA.def.map.200.bmp ../DEM/EQA.dem_par
# for comparison see also results/Moosfluh.EQA.def.map.200.jpg

# generate ASCII files of the results using disp_prt:
disp_prt pt_geo pmask_070A_target - pSLC_par itab_ts plat_lon phgt4 pdef pcct pdh_err pdef_err pdisp_ts1 $ref_point target.EQA.items.txt target.EQA.disp_tab.txt
# generate KMZ file for Google Earth for individual points, including deformation time-series plot for the points at the top level-of-detail
kml_ts_pt pt pmask_070A_target pSLC_par itab_ts pdisp_ts1 pdef phgt4 psigma pdh_err pdef_err pcct plat_lon target.EQA.disp_200.kmz target_kml - -0.15 0.15 0 hls.cm 0 -0.15 0.05 - $ref_point - - gamma

# --> kmz file Moosfluh.EQA.disp_200.kmz
# can be visualized using Google Earth
# for comparison see results/Moosfluh.EQA.disp_200.kmz

##############################

# Here we make a backup of the final solution of this processing
# this backup is also provided in the directory results

if [ -e backup_final_result ];then rm -rf backup_final_result; fi
mkdir backup_final_result
/bin/cp pt pt_geo pmask_070A plat_lon patm patm_mod pdef pdef_err pdh_err phgt4 pres psigma pcct ${dem_name}.EQA.def.map.150.bmp pSLC_par itab_ts pdisp_ts1 ./backup_final_result

# in this directory (and in results/bu20211027_final_result) it is possible
# to run the command

vu_disp pt_geo pmask_070A pSLC_par itab_ts pdisp_ts1 pdef phgt4 pcct pdh_err pdef_err plat_lon ${dem_name}.EQA.def.map.150.bmp -0.15 0.05 &

##############################################################################################
##############################################################################################
##############################################################################################

# Visualize the result also for the single-look and multi-look phases only.
# In both cases two scales (-0.15cm/year,0.15cm/year) and (-0.05cm/year,0.05cm/year) are used.

# visualize result based on single pixel values only
# prasdt_pwr pt_geo pmask_single ../DEM/EQA.dem_par pdef 1 - ../DEM/EQA.ave.rmli.bmp -0.15 0.15 0 hls.cm ${dem_name}.EQA.def.map.bmp 3
# add red "+" at reference point location
ras_pt pt_geo - ${dem_name}.EQA.def.map.bmp ${dem_name}.EQA.def.map.single_150.bmp 1 1 255 0 0 15 0 2 $ref_point
# view the rasterfile
#xv Aletsch.EQA.def.map.single_150.bmp

# visualize result based on single pixel values only
# prasdt_pwr pt_geo pmask_single ../DEM/EQA.dem_par pdef 1 - ../DEM/EQA.ave.rmli.bmp -0.05 0.05 0 hls.cm ${dem_name}.EQA.def.map.bmp 3
# add red "+" at reference point location
ras_pt pt_geo - ${dem_name}.EQA.def.map.bmp ${dem_name}.EQA.def.map.single_050.bmp 1 1 255 0 0 15 0 2 $ref_point
# view the rasterfile
#xv Aletsch.EQA.def.map.single_050.bmp

# visualize result based on multi-look phase values only
# prasdt_pwr pt_geo pmask_multilook ../DEM/EQA.dem_par pdef 1 - ../DEM/EQA.ave.rmli.bmp -0.15 0.15 0 hls.cm ${dem_name}.EQA.def.map.bmp 3
# add red "+" at reference point location
ras_pt pt_geo - ${dem_name}.EQA.def.map.bmp ${dem_name}.EQA.def.map.multilook_150.bmp 1 1 255 0 0 15 0 2 $ref_point
# view the rasterfile
#xv Aletsch.EQA.def.map.multilook_150.bmp

# visualize result based on multi-look phase values only
# prasdt_pwr pt_geo pmask_multilook ../DEM/EQA.dem_par pdef 1 - ../DEM/EQA.ave.rmli.bmp -0.05 0.05 0 hls.cm ${dem_name}.EQA.def.map.bmp 3
# add red "+" at reference point location
ras_pt pt_geo - ${dem_name}.EQA.def.map.bmp ${dem_name}.EQA.def.map.multilook_050.bmp 1 1 255 0 0 15 0 2 $ref_point
# view the rasterfile
#xv Aletsch.EQA.def.map.multilook_050.bmp

