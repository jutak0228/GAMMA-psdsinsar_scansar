#!/bin/bash

# Test step 1: determine new point list (using mkgrid)

work_dir="$1"
ref_date="$2"
tif="$3"

if [ -e input_files_all_single_look_test ];then rm -r input_files_all_single_look_test; fi
mkdir -p input_files_all_single_look_test

cp int/ave.cc_mask.bmp input_files_all_single_look_test/
cp input_files_orig/button_master.png input_files_all_single_look_test/
cp input_files_orig/gamma_logo.png input_files_all_single_look_test/
cp input_files_orig/${tif} input_files_all_single_look_test/
cp ipta/pt input_files_all_single_look_test/

cd input_files_all_single_look_test
if [ -e previous_ipta_result ];then rm -r previous_ipta_result; fi
mkdir -p previous_ipta_result

cp ../ipta/* previous_ipta_result/


