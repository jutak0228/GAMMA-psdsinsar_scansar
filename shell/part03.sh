#!/bin/bash

# Part 3: Coregister data

work_dir="$1"
ref_date="$2"
rlks="$3"
azlks="$4"

if [ -e rslc_prep ];then rm -r rslc_prep; fi
mkdir rslc_prep
cd rslc_prep

# copy burst slc to new folder
cp ../input_prep/dates .
# generate list of SLC_tab files
ls -1 ../input_prep/*.SLC_tab > SLC_tab_list

# cp ../input_prep/*.vv.SLC_tab .
# cp ../input_prep/*.vv.slc.iw? .
# cp ../input_prep/*.vv.slc.iw?.par .
# cp ../input_prep/*.vv.slc.iw?.tops_par .

# <revised part>

# coregister using the script ScanSAR_coreg_stack.py
# - ScanSAR_coreg_stack.py is able to interpret the paths to the files even when the SLC_tab files are not located in the current directory
# - to avoid co-registration issues due to decreasing coherence over increasing temporal baselines, we use the "--2nd_ref adjacent" option: temporal neighbor as secondary reference
ScanSAR_coreg_stack.py ../input_prep/${ref_date}.vv.SLC_tab SLC_tab_list ../DEM_prep/${ref_date}.hgt $3 $4 --2nd_ref adjacent --ID date --it1 1

# <old version>

# # prepare RSLC_tab files
# while read line; do sed -e 's/slc/rslc/g' ${line}.vv.SLC_tab > ${line}.vv.RSLC_tab; done < dates

# # rename reference date files
# rename "s/slc/rslc/" ${ref_date}.vv.slc.iw?
# rename "s/slc/rslc/" ${ref_date}.vv.slc.iw?.par
# rename "s/slc/rslc/" ${ref_date}.vv.slc.iw?.tops_par

# ### make dates_coreg_1 and dates_coreg_2 ###

# # get row number of reference date in dates file
# row_num=`cat dates | wc -l`
# ref_num=`grep -e ${ref_date} -n dates | sed -e 's/:.*//g'`
# ref_num_bf=`expr $ref_num - 1`
# ref_num_af=`expr $ref_num + 1`

# # prepare dates for coregistration
# # [1] neighbor slaves
# rm -f dates_coreg_1
# ref_date_bf=`head -n $ref_num_bf dates | tail -n 1`
# echo "$ref_date_bf $ref_date $rlks $azlks" > dates_coreg_1
# ref_date_af=`head -n $ref_num_af dates | tail -n 1`
# echo "$ref_date_af $ref_date $rlks $azlks" >> dates_coreg_1

# # [2] all other slaves
# rm -f dates_coreg_2
# ref_date_bf_col=`head -n $ref_num_bf dates` # dates list before reference date
# ref_num_af_num=`expr $row_num - $ref_num` # subtract the number of dates before reference date from total dates 
# ref_date_af_col=`tail -n $ref_num_af_num dates` # dates list after reference date

# for line in $ref_date_bf_col; do echo $line >> dates_bf; done
# for line in $ref_date_af_col; do echo $line >> dates_af; done
# sort -r dates_bf >> dates_bfr
# sort -r dates_af >> dates_afr

# sed -e '1d' dates_af > dates_af1 # delete first row and this column can be the first col
# sed -e '$d' dates_af > dates_af2 # delete last row and this column can be the second col
# sed -e '1d' dates_bfr > dates_bfr1 # delete first row and this column can be the first col
# sed -e '$d' dates_bfr > dates_bfr2 # delete last row and this column can be the second col

# awk 1 dates_af1 dates_bfr1 > dates_col1
# awk 1 dates_af2 dates_bfr2 > dates_col2
# paste dates_col1 dates_col2 > dates_coreg_2tmp

# while read line; do echo "$line $ref_date $rlks $azlks" >> dates_coreg_2; done < dates_coreg_2tmp
# rm -f dates_af dates_af1 dates_af2 dates_afr dates_bf dates_bfr dates_bfr1 dates_bfr2 dates_col1 dates_col2 dates_coreg_2tmp

# ### coregistration by using dates_coreg_1 and dates_coreg_2 ###

# # coregister neighbor slaves with reference
# run_all.pl dates_coreg_1 'ScanSAR_coreg.py $2.vv.RSLC_tab $2 $1.vv.SLC_tab $1 $1.vv.RSLC_tab ../DEM_prep/$2.hgt $3 $4'

# # coregister other slaves with reference, using neighbor slave
# run_all.pl dates_coreg_2 'ScanSAR_coreg.py $3.vv.RSLC_tab $3 $1.vv.SLC_tab $1 $1.vv.RSLC_tab ../DEM_prep/$3.hgt $4 $5 --RSLC3_tab $2.vv.RSLC_tab --RSLC3_ID $2'

# # remove burst SLCs
# run_all.pl dates 'rm -f $1.vv.slc $1.vv.slc.par $1.vv.slc.tops_par $1.vv.SLC_tab $1.vv.slc.iw? $1.vv.slc.iw?.par $1.vv.slc.iw?.tops_par'

cd ../


