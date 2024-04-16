#!/bin/bash

# you must choose one of iws1-3 sub-swaths and must not select multiple swaths

##########################################################################
# [flags] 
##########################################################################
part_01a="off" 		 	 # [1-a] iws slc data extraction bf edit
part_01b="off"		 	 # [1-b] iws slc data extraction af edit
part_02="off"			 # [2] Prepare DEM and geocode reference
part_03="off"		 	 # [3] coregister data
part_04="off"			 # [4] Deramp the data, oversample the data in range direction, and crop the area of interest
part_05="off"			 # [5] Compute the average image
part_06="off"			 # [6] Prepare DEM, geocode including refinement, produce geocoded average image, prepare height map in RDC coordinates
### Parts 7 to 10: generation of the combined multi-reference stack ###
part_07="off"			 # [7] Generate multi-look differential interferometric phases
part_08="off"			 # [8] Generate single-pixel (PSI) differential interferometric phases
part_09="off"			 # [9] Combined PSI and multi-look lists and phases into one combined vector data set and generate pmask files documenting the origin of a value (single pixel or multi-look)
part_10="off"			 # [10] Reference point selection
### Parts 11 to 13: unwrap differential phase, estimate atmospheric phases, calculate height correction and calculate a mask
part_11="off"		 	# [11] Determine atmospheric phases using multi-reference stack (using multi_def_pt)
part_12a="off"		 	# [12a] Estimate height correction and update atmospheric phases using multi-reference stack
part_12b="off"		 	# [12b] Update height corrections and atmospheric phases using multi-reference stack
part_12c="off"		 	# [12c] Update height corrections and atmospheric phases using multi-reference stack
part_13="off"			 # [13] Update height corrections and atmospheric phases and estimate a deformation rate
part_14="off"			 # [14] Phases are converted into a deformation time series and atmospheric phases
part_15="off"			 # [15] Some comparisons and considerations
part_16="off"			 # [16] Results

### try single look test for higher quality products ###
prep_slt="off"			 # preparation for single look test
part_17="off"			 # [17] determine new point list (using mkgrid)
part_18="off"			 # [18] import (expand) previous result to new point list
part_19="off"			 # [19] update the solution  using def_mod_pt
part_19a="off"		 # [19a] update phgt, patm using def_mod_pt with one-dimensional regression
part_19b="off"		 # [19b] update phgt, patm using def_mod_pt with one-dimensional regression
part_19c="off"		 # [19c] last iteration, don't update terms but just use unwrapped phase
part_20="off"			 # [20] add up unwrapped phase terms to total unwrapped multi-ref DInSAR phase
part_21="off"			 # [21a] Check and improve unwrapping consistency using mb_pt
part_22="off"			 # [22] Using the consistently unwrapped phases we try to correctly unwrap further pixels.
part_23="off"			 # [23] Phase interpretation and generation of time-series
part_24="off"			 # [24] Remove outliers directly based on spatial consistency of average deformation rate
part_25="off"			 # [25] Generation of single-look time-series with noise and temporally filtered
part_26="off"			 # [26] Generation of spatially filtered time-series and related average rates
part_27="off"			 # [27] Preparation and visualization of results

####################################################################################
# setting parameters
####################################################################################
work_dir="/home/jutak/data/aletsch_rev/psdsinsar_scansar"
shell="${work_dir}/shell"
ref_date="20190809" # (temporally more or less in the centere of the considered period)
rlks_deramp="5"
azlks_deramp="1"
dem_name="aletsch_rev"
rlks="9"
azlks="1"
delta_t_max="-" # maximum number of days between passes
delta_n_max="3" # maximum scene number difference between passes
cc_thres_ds="0.1" # default: 0.1 --> glacier areas, layover and shadow areas, water surfaces and forests are below thres.
th_spcc="0.32" # default: 0.32 --> select ps points with spectral coherence 
th_msr="1.5" # default: 1.5 --> select ps points with dispersion index
ref_point="315737" # select reference point which is nearby point and has a higher backcatter than previous point

####################################################################################
# ps-dsinsar process
####################################################################################

if [ "${part_01a}" = "on" ];then bash ${shell}/part01a.sh ${work_dir} ${ref_date}; fi
if [ "${part_01b}" = "on" ];then bash ${shell}/part01b.sh ${work_dir} ${ref_date} ${rlks_deramp} ${azlks_deramp}; fi
if [ "${part_02}" = "on" ];then bash ${shell}/part02.sh ${work_dir} ${ref_date} ${rlks_deramp} ${azlks_deramp} ${dem_name}; fi
if [ "${part_03}" = "on" ];then bash ${shell}/part03.sh ${work_dir} ${ref_date} ${rlks_deramp} ${azlks_deramp}; fi
if [ "${part_04}" = "on" ];then bash ${shell}/part04.sh ${work_dir} ${ref_date} ${rlks_deramp} ${azlks_deramp}; fi
if [ "${part_05}" = "on" ];then bash ${shell}/part05.sh ${work_dir} ${ref_date} ${rlks} ${azlks}; fi
if [ "${part_06}" = "on" ];then bash ${shell}/part06.sh ${work_dir} ${ref_date} ${tif} ${dem_name}; fi
if [ "${part_07}" = "on" ];then bash ${shell}/part07.sh ${work_dir} ${ref_date} ${rlks} ${azlks} ${delta_t_max} ${delta_n_max} ${cc_thres_ds}; fi
if [ "${part_08}" = "on" ];then bash ${shell}/part08.sh ${work_dir} ${ref_date} ${rlks} ${azlks} ${th_spcc} ${th_msr}; fi
if [ "${part_09}" = "on" ];then bash ${shell}/part09.sh ${work_dir} ${ref_date} ${rlks} ${azlks}; fi
if [ "${part_10}" = "on" ];then bash ${shell}/part10.sh ${work_dir} ${ref_date} ${rlks} ${azlks}; fi
if [ "${part_11}" = "on" ];then bash ${shell}/part11.sh ${work_dir} ${ref_date} ${rlks} ${azlks} ${ref_point}; fi
if [ "${part_12a}" = "on" ];then bash ${shell}/part12a.sh ${work_dir} ${ref_date} ${rlks} ${azlks} ${ref_point}; fi
if [ "${part_12b}" = "on" ];then bash ${shell}/part12b.sh ${work_dir} ${ref_date} ${rlks} ${azlks} ${ref_point}; fi
if [ "${part_12c}" = "on" ];then bash ${shell}/part12c.sh ${work_dir} ${ref_date} ${rlks} ${azlks} ${ref_point}; fi
if [ "${part_13}" = "on" ];then bash ${shell}/part13.sh ${work_dir} ${ref_date} ${rlks} ${azlks} ${ref_point}; fi
if [ "${part_14}" = "on" ];then bash ${shell}/part14.sh ${work_dir} ${ref_date} ${rlks} ${azlks} ${ref_point} ${dem_name}; fi
if [ "${part_15}" = "on" ];then bash ${shell}/part15.sh ${work_dir} ${ref_date} ${rlks} ${azlks} ${ref_point} ${dem_name}; fi
if [ "${part_16}" = "on" ];then bash ${shell}/part16.sh ${work_dir} ${ref_date} ${rlks} ${azlks} ${ref_point} ${dem_name}; fi
if [ "${prep_slt}" = "on" ];then bash ${shell}/prep_slt.sh ${work_dir} ${ref_date} ${tif}; fi
if [ "${part_17}" = "on" ];then bash ${shell}/part17.sh ${work_dir} ${ref_date} ${rlks} ${azlks}; fi
if [ "${part_18}" = "on" ];then bash ${shell}/part18.sh ${work_dir} ${ref_date} ${ref_point} ${rlks} ${azlks}; fi
if [ "${part_19}" = "on" ];then bash ${shell}/part19.sh ${work_dir} ${ref_date}; fi
if [ "${part_19a}" = "on" ];then bash ${shell}/part19a.sh ${work_dir} ${ref_date} ${rlks} ${azlks}; fi
if [ "${part_19b}" = "on" ];then bash ${shell}/part19b.sh ${work_dir} ${ref_date} ${rlks} ${azlks}; fi
if [ "${part_19c}" = "on" ];then bash ${shell}/part19c.sh ${work_dir} ${ref_date} ${rlks} ${azlks}; fi
if [ "${part_20}" = "on" ];then bash ${shell}/part20.sh ${work_dir} ${ref_date}; fi
if [ "${part_21}" = "on" ];then bash ${shell}/part21.sh ${work_dir} ${ref_date} ${rlks} ${azlks}; fi
if [ "${part_22}" = "on" ];then bash ${shell}/part22.sh ${work_dir} ${ref_date} ${rlks} ${azlks}; fi
if [ "${part_23}" = "on" ];then bash ${shell}/part23.sh ${work_dir} ${ref_date} ${rlks} ${azlks}; fi
if [ "${part_24}" = "on" ];then bash ${shell}/part24.sh ${work_dir} ${ref_date} ${rlks} ${azlks}; fi
if [ "${part_25}" = "on" ];then bash ${shell}/part25.sh ${work_dir} ${ref_date} ${rlks} ${azlks}; fi
if [ "${part_26}" = "on" ];then bash ${shell}/part26.sh ${work_dir} ${ref_date} ${rlks} ${azlks}; fi
if [ "${part_27}" = "on" ];then bash ${shell}/part27.sh ${work_dir} ${ref_date} ${dem_name}; fi


