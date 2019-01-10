from pandas.core import datetools
from os.path import join
from SWOTRiver import SWOTRiverEstimator
from RiverObs import RiverReachWriter
from matplotlib.pyplot import *

#data t
# data_dir = 'C:/Users/markh/Documents/riverobs-data/'
data_dir = '/home/markwh/Documents/riverobs-data/'
# db_directory='~/Documents/RiverObs/data/SAC1051'

# width_db_file=join(db_directory,'SAC_width_db_whole.h5')



shape_file_root = data_dir + 'Sacramento-NodeDatabase/Sacramento-NodeDatabase'
centerline_root = data_dir + 'Sacramento-ReachDatabase/Sacramento-ReachDatabase'

pixc_dir= data_dir + 'Sac PIXC-20181101T193846Z-001/Sac PIXC/'
# l2_file=(data_dir + '606_ellip_off_heights_sac_cycle_0001_pass_0264_presum2.125.AzPTR.Presum.Noise.LeftSwath.Unflat.Multilook_L2PIXC.nc')

l2_file=(pixc_dir + '109_ellip_off_heights_sac_cycle_0001_pass_0249_presum2.125.AzPTR.Presum.Noise.LeftSwath.Unflat.Multilook_L2PIXC.nc')


# output_dir='/data/scratch/rui/RiverObs-develop/SAC1051/L2_HR_obs_ratio_5'

output_dir='riverobs-output'

root_name = 'SWOT_L2_HR_River_SP_008_264_Sac_20090606T000000'
fout_reach = join(output_dir,root_name+'_Reach')
fout_node = join(output_dir,root_name+'_Node')
fout_index = join(output_dir,root_name+'_index.nc')
lonmin = -122.071
latmin = 38.917
lonmax =  -121.781
latmax = 39.754
bounding_box = lonmin,latmin,lonmax,latmax
xtrack_kwd='cross_track_medium'
min_reach_obsrvd_ratio = 0.5



# either 'no_layover_latitude' (a priori lat) or 'latitude' (estimated lat)
lat_kwd = 'latitude_medium'
# either 'no_layover_longitude' (a priori lon) or 'longitude' (estimated lat)
lon_kwd = 'longitude_medium'
# either 'classification' (estimated classification)
# or 'no_layover_classification' (truth classification)
class_kwd = 'classification'
# either 'height' (estimated height) or 'water_height' (truth height)
height_kwd = 'height_medium'


# The list of classes to consider for potential inundation.
# The truth classes are [1], if no_layover_classification' is used.
# If estimated classification is used, the choice depends on whether
# use_fractional_inundation is set.
# If it is not set, either [3,4] or [4] should be used.
# If it is set, [2,3,4] or [3,4] should be used.
class_list = [2,3,4,5]

# If the L2 water file has been updated to contain the fractional # inundation, this is the name of the variable. If it has not been # updated or you do not wish to use it, set this to None
fractional_inundation_kwd = 'continuous_classification'

# This corresponds to the classes set above.
# If True, use fractional inundation estimate to get the inundated area for this class. # If False, assume that this class is fully flooded.
use_fractional_inundation=[True, True, False, False]
use_segmentation=[False, True, True, True]
use_heights=[False, True, True, False]



# This is the minimum number of measurements that the data set must have.

min_points=100

# The fourth set of inputs have to do with the reaches and width data base.

# The clip_buffer is a buffer (in degrees) that is drawn around the data # bounding box so that the full reach is included and is not broken if

# the river. 0.01 ~ 1km

clip_buffer=0.01



# The fifth set of options has to do with how the data are sampled and

# quantities are estimated



# This option is only possible if you have an a priori estimate # of width for each width point. It will load that width into

# the centerline for comparison with the estimated data.



use_width_db = False



# This option determines the separation between centerline nodes.

# If set to None, the the spacing in the input reach is used.

# The units are meters. The default is to use the input reach spacing.

ds = None

# The next set of options are required if one desires to refine

# the centerline if it does not align well with the data.

# If you do not know what these are, don't change them.

refine_centerline=False # Set to True if you want to refine the centerline.

smooth=1.e-2

alpha=1.

max_iter=0

# parameters for node height gaussian averaging, turn enhanced on for L2 pixels
enhanced=True
max_window_size=10000
min_sigma=1000
window_size_sigma_ratio=5



# This is how far from the centerline points are accepted

scalar_max_width=600

# This variable states how many valid data points are required before # a node can be consired to have a sufficient number of observations.

minobs = 100

# Set this if there seem to be issues with the first/last nodes.

# This can happen sometimes in the near range.

trim_ends = True

# These are the fitting algorithms desired for mean height and slope estimation.

# More than one type of fit can be requested.

# 'OLS': ordinary least square

# 'WLS': weighted least squares

# 'RLM': Robust Linear Model

fit_types=['OLS','WLS','RLM']

# These are the minimum number of points required for a slope fit

min_fit_points = 3

# These are options useful for interctively playing with the data, but need not # be set for batch processing.

# verbose Output progress to stdout

# store_obs Keep the river observations for inspection
# store_reachesKeep the river reaches for inspection

# store_fits=True Keep the fit results for inspection


# Read the data and estimate the flooded area.

river_estimator = SWOTRiverEstimator(l2_file,
                                     bounding_box=bounding_box,
                                     lat_kwd=lat_kwd,
                                     lon_kwd=lon_kwd,
                                     class_kwd=class_kwd,
                                     height_kwd=height_kwd,
                                     class_list=class_list,
                                     fractional_inundation_kwd=fractional_inundation_kwd,
                                     use_fractional_inundation=use_fractional_inundation,
                                     use_segmentation=use_segmentation,
                                     use_heights=use_heights,
                                     min_points=min_points,
                                     verbose=True,store_obs=True,
                                     trim_ends = trim_ends,
                                     xtrack_kwd=xtrack_kwd,
                                     store_reaches=True,
                                     store_fits=True,
                                     output_file=fout_index,
                                     min_reach_obsrvd_ratio = min_reach_obsrvd_ratio,
                                     proj='laea',x_0=0,y_0=0,lat_0=39.3355,lon_0=-121.926)



# Load the reaches and width data base

river_estimator.get_reaches(shape_file_root, clip_buffer=clip_buffer)
river_estimator.get_centerlines(centerline_root, clip_buffer=clip_buffer)


river_reach_collection = river_estimator.process_reaches(scalar_max_width=scalar_max_width,
                                                         minobs=minobs,min_fit_points=min_fit_points,
                                                         fit_types=fit_types,
                                                         use_width_db = use_width_db,
                                                         ds=ds,
                                                         refine_centerline=refine_centerline,
                                                         smooth=smooth,alpha=alpha,
                                                         max_iter=max_iter,
                                                         max_window_size=max_window_size,
                                                         min_sigma=min_sigma,
                                                         window_size_sigma_ratio=window_size_sigma_ratio,
                                                         enhanced=enhanced)


type(river_reach_collection[0])


reach_output_variables = ['reach_id','time_day','p_latitud','p_longitud','height',
                         'height_u','geoid_hght','slope','slope_u','width','width_u',
                         'slope2','slope2_u','d_x_area','d_x_area_u',
                         'area_detct','area_det_u','discharge','dischg_u','xtrk_dist','obs_ratio']

node_output_variables = ['reach_id','node_id','longitude','latitude',
                        'height','geoid_hght','width',
                        'area_detct','xtrk_dist','wet_error','inst_error' ,'n_good_pix']

writer = RiverReachWriter(river_reach_collection,
                          node_output_variables,
                          reach_output_variables)

driver = 'ESRI shapefile'
writer.write_nodes_ogr(fout_node,driver=driver)
writer.write_reaches_ogr(fout_reach,driver=driver)

print('Successfuly estimated river heights and slopes')
