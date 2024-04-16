#!/usr/bin/env python
import sys
import os
import shutil
import datetime
import getopt
try:
  import py_gamma as pg
except ImportError as e:
  if 'py_gamma' in str(e):
    print('\nERROR: cannot load py_gamma.py')
    print('       setting the environmental variable "PYTHONPATH" in your .bashrc as follows may solve the issue:')
    print('       export PYTHONPATH=.:$GAMMA_HOME:$PYTHONPATH\n')
  else:
    print('\nERROR: ' + str(e))
  sys.exit()

def usage():
  print("""
usage: unwrapping_correction_mb_pt.py <plist> <pSLC_par> <itab> <pdiff_unw> <np_ref> <SLC_ref_par> <pdiff_unw_corr> [options]
    plist           (input) point list (INT)
    pSLC_par        (input) stack of SLC/MLI parameters (binary)
    itab            (input) table associating interferogram stack records with pairs of SLC stack records (text)
    pdiff_unw       (input) point data of unwrapped differential phases for interferogram pairs specified in the itab (FLOAT)
    np_ref          point number for the phase reference point (beginning from 0)
    SLC_ref_par     (input) SLC parameter file of the image used for geometric coregistration
    pdiff_unw_corr  (output) point data of corrected unwrapped differential phases for interferogram pairs specified in the itab (FLOAT)
    
    --pmask name        point data stack of mask values (UCHAR)
    --pdh_sim name      phase related to the total height correction (FLOAT)
    --phgt name         point heights from a DEM (FLOAT)
    --no_cleaning       keep intermediate files
  """)
  print("Python version: " + sys.version)
  sys.exit()

def check_output(status, cleaning, tmp_dir):
  if (status != 0):
    print("\nERROR in previous command\n")
    
    if cleaning:
      try:
        shutil.rmtree(tmp_dir)
      except OSError:
        print("\nDeletion of the directory %s failed" % tmp_dir)
      else:
        print("\nSuccessfully deleted the directory %s" % tmp_dir)
    
    sys.exit(-1)

def main():
  print('*** unwrapping_correction_mb_pt.py: Script to correct phase unwrapping for a multi-reference stack using model produced by mb_pt ***')
  print('*** Copyright 2021 Gamma Remote Sensing, v1.0 1-Dec-2021 cm/uw ***')
  
  # init values
  t_cur = datetime.datetime.now()
  tmp_dir = 'tmp_dir_unw_corr_' + str(int(t_cur.hour)) + str(int(t_cur.minute)) + str(int(t_cur.second)) + str(int(t_cur.microsecond))
  cleaning = 1            # 0: no, 1: yes
  pdh_sim = ''
  phgt = ''
  patm_mod = ''
  pmask = '-'
  
  # verbose mode
  pg.is_verbose = True
  
  try:
    opts, args = getopt.gnu_getopt(sys.argv[1:], "", ["pmask=", "pdh_sim=", "phgt=", "no_cleaning"])
  except getopt.GetoptError as err:
    print(str(err))  # will print something like "option -a not recognized"
    usage()
  
  if len(args) < 6:
    if len(args) > 0:
      print("\nERROR: insufficient data parameters on the command line")
    usage()

  print("\nunwrapping_correction_mb_pt.py arguments: %s" %str(args))
  print("unwrapping_correction_mb_pt.py options: %s\n" %str(opts))
  
  # point list
  plist = args[0]
  
  if not os.path.isfile(plist):
    print("\nERROR: %s not found\n" %plist)
    sys.exit(-1)
  
  # stack of SLC/MLI parameters
  pSLC_par = args[1]
  
  if not os.path.isfile(pSLC_par):
    print("\nERROR: %s not found\n" %pSLC_par)
    sys.exit(-1)
  
  # table associating interferogram stack records with pairs of SLC stack records
  itab = args[2]
  
  if not os.path.isfile(itab):
    print("\nERROR: %s not found\n" %itab)
    sys.exit(-1)
  
  # point data of unwrapped differential phases for interferogram pairs specified in the itab
  pdiff_unw = args[3]
  
  if not os.path.isfile(pdiff_unw):
    print("\nERROR: %s not found\n" %pdiff_unw)
    sys.exit(-1)
  
  # point number for the phase reference point
  np_ref = args[4]
  
  # SLC parameter file of the image used for geometric coregistration
  SLC_ref_par = args[5]
  
  if not os.path.isfile(SLC_ref_par):
    print("\nERROR: %s not found\n" %SLC_ref_par)
    sys.exit(-1)
  
  # point data of corrected unwrapped differential phases for interferogram pairs specified in the itab
  pdiff_unw_corr = args[6]
  
  for o, a in opts:
    # point data stack of mask values
    if (o == "--pmask"):
      pmask = a
      
      if not os.path.isfile(pmask):
        print("\nERROR: %s not found\n" %pmask)
        sys.exit(-1)
      
    # phase related to the total height correction
    elif (o == "--pdh_sim"):
      pdh_sim = a
      
      if not os.path.isfile(pdh_sim):
        print("\nERROR: %s not found\n" %pdh_sim)
        sys.exit(-1)
    
    # point heights from a DEM
    elif (o == "--phgt"):
      phgt = a
      
      if not os.path.isfile(phgt):
        print("\nERROR: %s not found\n" %phgt)
        sys.exit(-1)
    
    # no_cleaning
    elif (o == "--no_cleaning"):
      cleaning = 0
  
  # set output file names
  if pdh_sim == '':
    pdiff_unw1 = pdiff_unw
  else:
    pdiff_unw1 = tmp_dir + '/' + pdiff_unw + '.1'
  if phgt == '':
    pdiff_unw2 = pdiff_unw1
  else:
    pdiff_unw2 = tmp_dir + '/' + pdiff_unw + '.2'
    patm_mod = tmp_dir + '/' + 'patm_mod'
  pdiff_unw2a = tmp_dir + '/' + pdiff_unw + '.2a'
  itab_ts = tmp_dir + '/' + 'itab_ts'
  pdiff_ts = tmp_dir + '/' + 'pdiff_ts'
  pdiff_sim = tmp_dir + '/' + 'pdiff_sim'
  pdphase = tmp_dir + '/' + 'pdphase'
  pdphase_cpx = tmp_dir + '/' + 'pdphase.cpx'
  pdphase_cpx_unw = tmp_dir + '/' + 'pdphase.cpx.unw'
  pmodel = tmp_dir + '/' + 'pmodel'
  ppcorrection = tmp_dir + '/' + 'ppcorrection'
  
  # create temporary directory
  if not os.path.isdir(tmp_dir):
    try:
      os.mkdir(tmp_dir)
    except OSError:
      print("\nERROR: Creation of the directory %s failed\n" % tmp_dir)
      sys.exit(-1)
    else:
      print("\nSuccessfully created the directory %s" % tmp_dir)
  
  if pdh_sim != '':
    # subtract the phase related to the total height correction from pdiff.unw
    status = pg.sub_phase_pt(plist, pmask, pdiff_unw, '-', pdh_sim, pdiff_unw1, 0, 0)
    check_output(status, cleaning, tmp_dir)

  if phgt != '':
    # create model of atmospheric phase
    status = pg.atm_mod_pt(plist, pmask, pdiff_unw1, phgt, patm_mod)
    check_output(status, cleaning, tmp_dir)
    
    # subtract model of atmospheric phase
    status = pg.sub_phase_pt(plist, pmask, pdiff_unw1, '-', patm_mod, pdiff_unw2, 0, 0)
    check_output(status, cleaning, tmp_dir)

  # subtract reference point phase from each layer:
  status = pg.spf_pt(plist, pmask, SLC_ref_par, pdiff_unw2, pdiff_unw2a, '-', 2, 25, 0, '-', np_ref, 1)
  check_output(status, cleaning, tmp_dir)

  # run mb_pt without spatial smoothing
  status = pg.mb_pt(plist, pmask, pSLC_par, itab, pdiff_unw2a, np_ref, '-', itab_ts, pdiff_ts, pdiff_sim, '-', 1, '-', 0.0, '-', '-', '-', SLC_ref_par)
  check_output(status, cleaning, tmp_dir)

  # difference between pdiff_unw0a and pdiff_sim
  status = pg.sub_phase_pt(plist, pmask, pdiff_unw2a, '-', pdiff_sim, pdphase, 0, 0)
  check_output(status, cleaning, tmp_dir)
  
  # wrap pdphase
  status = pg.unw_to_cpx_pt(plist, pmask, pdphase, '-' , pdphase_cpx)
  check_output(status, cleaning, tmp_dir)
  
  # create model with very small phase for phase unwrapping
  status = pg.lin_comb_pt(plist, pmask, pdphase, '-', pdphase, '-', pmodel, '-', 0.0001, 0., 0., 2, 0)
  check_output(status, cleaning, tmp_dir)

  # unwrap using model
  status = pg.unw_model_pt(plist, pmask, pdphase_cpx, '-', pmodel, pdphase_cpx_unw)
  check_output(status, cleaning, tmp_dir)
  
  # calculate phase unwrapping correction factor of 2*pi
  status = pg.lin_comb_pt(plist, pmask, pdphase_cpx_unw, '-', pdphase, '-', ppcorrection, '-', 0.0, 1., -1., 2, 0)
  check_output(status, cleaning, tmp_dir)

  # input phase correction by adding the ambiguity corrections
  status = pg.lin_comb_pt(plist, pmask, pdiff_unw, '-', ppcorrection, '-', pdiff_unw_corr, '-', 0.0, 1., 1., 2, 1)
  check_output(status, cleaning, tmp_dir)

  if cleaning:
    try:
      shutil.rmtree(tmp_dir)
    except OSError:
      print("\nDeletion of the directory %s failed" % tmp_dir)
    else:
      print("\nSuccessfully deleted the directory %s" % tmp_dir)
  
  t_end = datetime.datetime.now()
  delta_t = t_end - t_cur
  print("\nend of unwrapping_correction_mb_pt.py, elapsed time (s): %s\n" %(str(delta_t.total_seconds())))

  return 0

if __name__ == "__main__":
  main()