#!/bin/bash

conda activate RiverObs
homedir='C:/Users/markh/'
rodir=$homedir/Documents/RiverObs/src/bin
configdir=$homedir/Documents/swot-error/config
latestruns='D:/data/riverobs-output/sacruns_latest'

dirs=$(find $latestruns -name composite -exec dirname {} \;)

ls $rodir

for dir in $dirs; do
  echo $dir
  
  
  # cp $dir/rt_gdem.nc $dir/simple/
  # cp $dir/rt_gdem.nc $dir/composite/
  # cp $dir/rt_gdem.nc $dir/frac/
  
  # cp $dir/rt_gdem_dil2.nc $dir/simple/
  # cp $dir/rt_gdem_dil2.nc $dir/composite/
  # cp $dir/rt_gdem_dil2.nc $dir/frac/
  
  # cp $dir/pcv_gdem.nc $dir/simple/
  # cp $dir/pcv_gdem.nc $dir/composite/
  # cp $dir/pcv_gdem.nc $dir/frac/
  
  
  python $rodir/swot_pixc2rivertile.py $dir/simple/pixel_cloud_new_usds.nc $dir/simple/rt_usds.nc $dir/simple/pcv_usds.nc $configdir/config-simple.rdf
  python $rodir/swot_pixc2rivertile.py $dir/composite/pixel_cloud_new_usds.nc $dir/composite/rt_usds.nc $dir/composite/pcv_usds.nc $configdir/config-composite.rdf  
  python $rodir/swot_pixc2rivertile.py $dir/frac/pixel_cloud_new_usds.nc  $dir/frac/rt_usds.nc $dir/frac/pcv_usds.nc $configdir/config-frac.rdf
  
  python $rodir/swot_pixc2rivertile.py $dir/fake_pixc_usds.nc  $dir/rt_gdem_usds.nc $dir/pcv_gdem_usds.nc $configdir/config_newprior_gdem.rdf
  cp $dir/rt_gdem_usds.nc $dir/simple/
  cp $dir/rt_gdem_usds.nc $dir/composite/
  cp $dir/rt_gdem_usds.nc $dir/frac/
  
  cp $dir/pcv_gdem_usds.nc $dir/simple/
  cp $dir/pcv_gdem_usds.nc $dir/composite/
  cp $dir/pcv_gdem_usds.nc $dir/frac/
    
done

conda deactivate