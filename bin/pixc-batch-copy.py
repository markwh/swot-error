import pandas as pd
import shutil as su
import os
rorundf = pd.read_csv('src/roruns.csv')

for index, row in rorundf.iterrows():
  # copy pixel_cloud.nc from indir to outdir
  
  inloc = os.path.expandvars(row['indir']) + '/pixel_cloud.nc'
  outloc = os.path.abspath(os.path.expandvars(row['outdir']))
  print(inloc)
  print(outloc)
  su.copy(inloc, row['outdir'])

