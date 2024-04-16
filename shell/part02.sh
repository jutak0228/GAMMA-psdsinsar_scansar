#!/bin/bash

# Part 2: Prepare DEM and geocode reference

work_dir="$1"
ref_date="$2"
rlks="$3"
azlks="$4"
dem_name="$5"

cd input_prep

# multilook reference
multi_look_ScanSAR ${ref_date}.vv.SLC_tab ${ref_date}_${rlks}_${azlks}.vv.mli ${ref_date}_${rlks}_${azlks}.vv.mli.par ${rlks} ${azlks} 1
# estimate corber latitude and longitude
if [ -e SLC_corners.txt ]; then rm -f SLC_corners.txt; fi
SLC_corners ${ref_date}_${rlks}_${azlks}.vv.mli.par > SLC_corners.txt
# setting variable for clipping dem data
# -->
# lower left  corner longitude, latitude (deg.): 139.06  35.15
# upper right corner longitude, latitude (deg.): 140.29  36.06

lowleft_lat=`cat SLC_corners.txt | grep "lower left" | awk -F" " '{print $8}' | tr -d [:space:]`
lowleft_lon=`cat SLC_corners.txt | grep "lower left" | awk -F" " '{print $7}' | tr -d [:space:]`
uppright_lat=`cat SLC_corners.txt | grep "upper right" | awk -F" " '{print $8}' | tr -d [:space:]`
uppright_lon=`cat SLC_corners.txt | grep "upper right" | awk -F" " '{print $7}' | tr -d [:space:]`

# download filled SRTM1 using elevation module
eio clip -o ../input_files_orig/SRTM1_elevation.tif --bounds $lowleft_lon $lowleft_lat $uppright_lon $uppright_lat
# eio --product SRTM1 clip -o ../input_files_orig/SRTM1_elevation.tif --bounds 7.64 45.68 9.24 46.92

if [ -e ../DEM_prep ];then rm -r ../DEM_prep; fi
mkdir ../DEM_prep
cd ../DEM_prep

/bin/cp ../input_prep/${ref_date}_${rlks}_${azlks}.vv.mli .
/bin/cp ../input_prep/${ref_date}_${rlks}_${azlks}.vv.mli.par .

# convert the GeoTIFF DEM into Gamma Software format, including geoid to ellipsoid height reference conversion
dem_import ../input_files_orig/SRTM1_elevation.tif SRTM1.dem SRTM1.dem_par 0 1 $DIFF_HOME/scripts/egm96.dem $DIFF_HOME/scripts/egm96.dem_par 0

# visualize DEM as a shaded relief
#disdem_par ${dem_name}.dem ${dem_name}.dem_par

# <revised part>

# let's use the script "geocoding.py" to geocode the MLI image with refinement and calculate the DEM in radar coordinates
geocoding.py ${ref_date}_${rlks}_${azlks}.vv.mli ${ref_date}_${rlks}_${azlks}.vv.mli.par SRTM1.dem SRTM1.dem_par $ref_date --kml --seg ${dem_name} --thres 0.3

# check the results
# more 20190809.geocoding_quality
# -->
# ...
# final solution: 664 offset estimates accepted out of 980 samples
# final range offset poly. coeff.:                0.31963
# final azimuth offset poly. coeff.:             -0.08588
# final model fit std. dev. (samples) range: 0.2610   azimuth: 0.4283
# ...

# compare "simulated" image with MLI
# dis2pwr 20190809.pix_gamma0 20190809_5_1.vv.mli 5323 5323

# --> looks good

# visualize height map (color scale with 500m cycle)
# disdt_pwr 20190809.hgt 20190809_5_1.vv.mli 5323 - - 0 500 1 rmg.cm - - 24

cd ../


