#!/bin/bash

# Test step 3: update the solution  using def_mod_pt

work_dir="$1"
ref_date="$2"

cd ${work_dir}/ipta_test

# thanks to the available small list solution we can directly move to the iteration of the large list solution using def_mod_pt

##########################

# initialize iteration:

SLC2pt SLC_tab pt - pSLC_par pSLC -
intf_pt pt - itab - pSLC pint 0

