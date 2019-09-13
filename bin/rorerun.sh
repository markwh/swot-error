#!/bin/bash

conda activate RiverObs
homedir='C:/Users/markh/'
rodir=$homedir/Documents/RiverObs/src/bin
configdir=$homedir/Documents/swot-error/config
latestruns='D:/data/riverobs-output/sacruns_latest'

dirs=$(find $latestruns -name pixel_cloud_new.nc -exec dirname {} \;)

ls $rodir

for dir in $dirs; do
  echo $dir
  
  # rm -r $dir/simple
  # rm -r $dir/composite
  # rm -r $dir/frac
  
  mkdir $dir/simple
  mkdir $dir/composite
  mkdir $dir/frac
  
  cp $dir/rt_gdem.nc $dir/simple/
  cp $dir/rt_gdem.nc $dir/composite/
  cp $dir/rt_gdem.nc $dir/frac/
  
  cp $dir/rt_gdem_dil2.nc $dir/simple/
  cp $dir/rt_gdem_dil2.nc $dir/composite/
  cp $dir/rt_gdem_dil2.nc $dir/frac/
  
  cp $dir/pcv_gdem.nc $dir/simple/
  cp $dir/pcv_gdem.nc $dir/composite/
  cp $dir/pcv_gdem.nc $dir/frac/
  
  
  python $rodir/swot_pixc2rivertile.py $dir/pixel_cloud_new.nc $dir/simple/rt.nc $dir/simple/pcv.nc $configdir/config-simple.rdf
  python $rodir/swot_pixc2rivertile.py $dir/pixel_cloud_new.nc $dir/composite/rt.nc $dir/composite/pcv.nc $configdir/config-composite.rdf  
  python $rodir/swot_pixc2rivertile.py $dir/pixel_cloud_new.nc  $dir/frac/rt.nc $dir/frac/pcv.nc $configdir/config-frac.rdf
    
done

conda deactivate