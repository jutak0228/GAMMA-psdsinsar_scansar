#!/bin/bash

# Part 6: Prepare DEM, geocode including refinement, produce geocoded average image, prepare height map in RDC coordinates

work_dir="$1"
ref_date="$2"
dem_name="$3"

if [ -e DEM ];then rm -r DEM; fi
mkdir DEM
cd DEM

cp ../ave/${ref_date}.rmli .
cp ../ave/${ref_date}.rmli.par .
cp ../ave/ave.rmli .
cp ../ave/ave.rmli.bmp .

# convert the GeoTIFF DEM into Gamma Software format, including geoid to ellipsoid height reference conversion
dem_import ../input_files_orig/SRTM1_elevation.tif SRTM1.dem SRTM1.dem_par 0 1 $DIFF_HOME/scripts/egm96.dem $DIFF_HOME/scripts/egm96.dem_par 0

# visualize DEM as a shaded relief
#disdem_par ${dem_name}.dem ${dem_name}.dem_par

# <revised part>

# let's use the script "geocoding.py" to geocode the MLI image with refinement and calculate the DEM in radar coordinates
geocoding.py ${ref_date}.rmli ${ref_date}.rmli.par SRTM1.dem SRTM1.dem_par $ref_date --kml --seg EQA --thres 0.3 --lat_ovr 3 --lon_ovr 3

# check the results
# more 20190809.geocoding_quality
# -->
# ...
# final solution: 758 offset estimates accepted out of 1007 samples
# final range offset poly. coeff.:                0.44119
# final azimuth offset poly. coeff.:             -0.06085
# final model fit std. dev. (samples) range: 0.3096   azimuth: 0.3881
# ...

# compare 20190809.pix_gamma0 with 20190809.rmli
# dis2pwr 20190809.pix_gamma0 20190809.rmli 900 900

# --> looks good

# refine geocoding look-up table
width=`grep "width" EQA.dem_par | awk -F":" '{print $2}'`
height=`grep "nlines" EQA.dem_par | awk -F":" '{print $2}'`

# geocode average image for visualization
mli_width=`grep "range_samples" ${ref_date}.rmli.par | awk -F":" '{print $2}'`
mli_hight=`grep "azimuth_lines" ${ref_date}.rmli.par | awk -F":" '{print $2}'`
geocode_back ${ref_date}.rmli $mli_width EQA.${ref_date}.lt_fine EQA.ave.rmli $width $height 5 0 - - 3

# generate PNG and KML files
raspwr EQA.ave.rmli $width - - - - 1.1 0.25 gray.cm EQA.ave.rmli.bmp
vispwr.py EQA.ave.rmli $width 2 -25. 5. -u EQA.ave.rmli.png -t
kml_map EQA.ave.rmli.png EQA.dem_par EQA.ave.rmli.kml

# calculate DEM in radar coordinates
# geocode ${ref_date}.lt_fine EQA.dem $width ${ref_date}.hgt $mli_width $mli_height

# visualize height usig 200m per color cycle
#dishgt 20190809.hgt ave.rmli 900 - - - 200

# create mask from layover shadow map in RDC coordinates (ls_map_rdc)
ls_map_mask ${ref_date}.ls_map_rdc $mli_width ${ref_date}.ls_map_rdc_mask.bmp
#disras ${ref_date}.ls_map_rdc_mask.bmp

