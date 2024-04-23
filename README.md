# GAMMA-psdsinsar_scansar

This GAMMA RS script is for IPTA analysis for ScanSAR datasets

## Requirements

GAMMA Software Modules:

The GAMMA software is grouped into four main modules:
- Modular SAR Processor (MSP)
- Interferometry, Differential Interferometry and Geocoding (ISP/DIFF&GEO)
- Land Application Tools (LAT)
- Interferometric Point Target Analysis (IPTA)

The user need to install the GAMMA Remote Sensing software beforehand depending on your OS.

For more information: https://gamma-rs.ch/uploads/media/GAMMA_Software_information.pdf

## Process step

Pre-processing: choose one of iws1-3 sub-swaths and must not select multiple swaths

Note: it should be processed orderly from the top (part_XX).

It needs to change the mark "off" to "on" when processing.

- part_01a="off" # [1-a] iws slc data extraction bf edit
- part_01b="off" # [1-b] iws slc data extraction af edit
- part_02="off" # [2] Prepare DEM and geocode reference
- part_03="off" # [3] coregister data
- part_04="off"	# [4] Deramp the data, oversample the data in range direction, and crop the area of interest
- part_05="off"	# [5] Compute the average image
- part_06="off"	# [6] Prepare DEM, geocode including refinement, produce geocoded average image, prepare height map in RDC coordinates
- Parts 7 to 10: generation of the combined multi-reference stack ###
- part_07="off"	# [7] Generate multi-look differential interferometric phases
- part_08="off"	# [8] Generate single-pixel (PSI) differential interferometric phases
- part_09="off"	# [9] Combined PSI and multi-look lists and phases into one combined vector data set and generate pmask files documenting the origin of a value (single pixel or multi-look)
- part_10="off"	# [10] Reference point selection
- Parts 11 to 13: unwrap differential phase, estimate atmospheric phases, calculate height correction and calculate a mask
- part_11="off"	# [11] Determine atmospheric phases using multi-reference stack (using multi_def_pt)
- part_12a="off" # [12a] Estimate height correction and update atmospheric phases using multi-reference stack
- part_12b="off" # [12b] Update height corrections and atmospheric phases using multi-reference stack
- part_12c="off" # [12c] Update height corrections and atmospheric phases using multi-reference stack
- part_13="off" # [13] Update height corrections and atmospheric phases and estimate a deformation rate
- part_14="off" # [14] Phases are converted into a deformation time series and atmospheric phases
- part_15="off" # [15] Some comparisons and considerations
- part_16="off" # [16] Results

### try single look test for higher quality products ###
- prep_slt="off" # preparation for single look test
- part_17="off" # [17] determine new point list (using mkgrid)
- part_18="off" # [18] import (expand) previous result to new point list
- part_19="off" # [19] update the solution  using def_mod_pt
- part_19a="off" # [19a] update phgt, patm using def_mod_pt with one-dimensional regression
- part_19b="off" # [19b] update phgt, patm using def_mod_pt with one-dimensional regression
- part_19c="off" # [19c] last iteration, don't update terms but just use unwrapped phase
- part_20="off" # [20] add up unwrapped phase terms to total unwrapped multi-ref DInSAR phase
- part_21="off" # [21a] Check and improve unwrapping consistency using mb_pt
- part_22="off" # [22] Using the consistently unwrapped phases we try to correctly unwrap further pixels.
- part_23="off" # [23] Phase interpretation and generation of time-series
- part_24="off" # [24] Remove outliers directly based on spatial consistency of average deformation rate
- part_25="off" # [25] Generation of single-look time-series with noise and temporally filtered
- part_26="off" # [26] Generation of spatially filtered time-series and related average rates
- part_27="off" # [27] Preparation and visualization of results
