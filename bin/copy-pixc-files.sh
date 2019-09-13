#!/bin/bash

# Copy pixel cloud files to subdirectories--simple, compoosite, frac.

latestruns='D:/data/riverobs-output/sacruns_latest'

# find all folders containing pixel_cloud_new.nc files
dirs=$(find $latestruns -name pixel_cloud_new.nc -exec dirname {} \;)

for dir in $dirs; do
  echo $dir
  
  # rm -r $dir/simple
  # rm -r $dir/composite
  # rm -r $dir/frac
    
  cp $dir/pixel_cloud.nc $dir/simple/
  cp $dir/pixel_cloud.nc $dir/composite/
  cp $dir/pixel_cloud.nc $dir/frac/
  
  cp $dir/pixel_cloud_new.nc $dir/simple/
  cp $dir/pixel_cloud_new.nc $dir/composite/
  cp $dir/pixel_cloud_new.nc $dir/frac/
  
    
done
