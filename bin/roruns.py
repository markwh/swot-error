#!/usr/bin/env python
# Does RiverObs runs and puts the results in a tidy directory

import argparse
import os
import glob
import pandas
import ast
import netCDF4
import shutil

import SWOTRiver.Estimate
import RDF
import bin.fake_pixc_from_gdem as fake_pixc_from_gdem # specify bin/ for now.
from SWOTRiver.products.pixcvec import L2PIXCVector

def get_config(file = './config/ro-config.rdf', 
            priordb = None,
            gdem = False,
            dilation = 0):
    config = RDF.RDF()
    config.rdfParse(file)
    config = dict(config)
    config['preseg_dilation_iter'] = str(dilation)
    
    if priordb is not None:
        config['reach_db_path'] = priordb
    
    if gdem:
        config['class_list'] = '[1]'
        config['use_fractional_inundation'] = '[False]'
        config['use_segmentation'] = '[True]'
        config['use_heights'] = '[True]'
    return config

def simple_rivertile(pixc_file, out_riverobs_file,
                     out_pixc_vector_file, config, delete=False, debug=False):
    """Simplified swot_pixc2rivertile funciton. 
    
    Largely copy-pasted from Alex's script. 
    """
    
    if (os.path.isfile(out_riverobs_file) or 
            os.path.isfile(out_pixc_vector_file)):
        if not delete:
            print("Skipping for existing output.")
            return
        os.remove(out_riverobs_file)
        os.remove(out_pixc_vector_file)

    # typecast most config values with eval since RDF won't do it for me
    # (excluding strings)
    for key in config.keys():
        if key in ['geolocation_method', 'reach_db_path', 'height_agg_method',
                   'area_agg_method']:
            continue
        config[key] = ast.literal_eval(config[key])

    l2pixc_to_rivertile = SWOTRiver.Estimate.L2PixcToRiverTile(
        pixc_file, out_pixc_vector_file)
    l2pixc_to_rivertile.load_config(config)
    l2pixc_to_rivertile.do_river_processing()
    l2pixc_to_rivertile.match_pixc_idx()
    l2pixc_to_rivertile.do_improved_geolocation()
    l2pixc_to_rivertile.flag_lakes_pixc()
    l2pixc_to_rivertile.build_products()
    
    # rewrite index file to make it look like an SDS one
    L2PIXCVector.from_ncfile(l2pixc_to_rivertile.index_file
        ).to_ncfile(l2pixc_to_rivertile.index_file)

    l2pixc_to_rivertile.rivertile_product.to_ncfile(out_riverobs_file)


def get_gdem_pixc(indir, out_pixc = 'fake_pixel_cloud.nc'):
    """Writes and returns a fake pixel cloud in the local directory."""
    pixc_file = indir + '/pixel_cloud.nc'
    gdem_file = glob.glob(indir + '/gdem_truth*nc')[0]
    fake_pixc_from_gdem.fake_pixc_from_gdem(gdem_file, pixc_file, out_pixc)
    return out_pixc

def rodryrun(outdir, indir, priordb, delete = False):
    print("out: ", outdir)
    print("in: ", indir)
    print("prior: ", priordb)

def rorun(outdir, indir, priordb, pixc_file_gdem=None, delete=False):
    """Do a single row's 2 riverobs runs."""
    outpath = os.path.abspath(os.path.expandvars(outdir))
    inpath = os.path.abspath(os.path.expandvars(indir))
    priorpath = os.path.abspath(os.path.expandvars(priordb))

    pixc_file = inpath + '/pixel_cloud.nc'
    if pixc_file_gdem is None:
        pixc_file_gdem = get_gdem_pixc(inpath)
    
    # Create directory if necessary
    try: 
        os.makedirs(outpath)
    except FileExistsError:
        # directory exists
        pass
    
    # output file names
    out_ro_file = outpath + '/rt.nc'
    out_pcv_file = outpath + '/pcv.nc'
    out_ro_file_gdem = outpath + '/rt_gdem.nc'
    out_pcv_file_gdem = outpath + '/pcv_gdem.nc'
    # out_ro_file_dil = outpath + '/rt_dil.nc' # pre-seg dialation
    # out_pcv_file_dil = outpath + '/pcv_dil.nc' # pre-seg dilation
    out_ro_file_gdem_dil1 = outpath + '/rt_gdem_dil1.nc' # pre-seg dialation
    out_pcv_file_gdem_dil1 = outpath + '/pcv_gdem_dil1.nc' # pre-seg dilation
    out_ro_file_gdem_dil2 = outpath + '/rt_gdem_dil2.nc' # pre-seg dialation
    out_pcv_file_gdem_dil2 = outpath + '/pcv_gdem_dil2.nc' # pre-seg dilation
    out_ro_file_gdem_dil3 = outpath + '/rt_gdem_dil3.nc' # pre-seg dialation
    out_pcv_file_gdem_dil3 = outpath + '/pcv_gdem_dil3.nc' # pre-seg dilation
    out_ro_file_gdem_dil4 = outpath + '/rt_gdem_dil4.nc' # pre-seg dialation
    out_pcv_file_gdem_dil4 = outpath + '/pcv_gdem_dil4.nc' # pre-seg dilation
    
    
    config1 = get_config(priordb=priorpath, gdem=False)
    config2 = get_config(priordb=priorpath, gdem=True)
    config3 = get_config(priordb=priorpath, gdem=True, dilation=1)
    config4 = get_config(priordb=priorpath, gdem=True, dilation=2)
    config5 = get_config(priordb=priorpath, gdem=True, dilation=3)
    config6 = get_config(priordb=priorpath, gdem=True, dilation=4)
    
    # do 3 separate runs--with and without gdem, with and without dilation
    simple_rivertile(pixc_file=pixc_file, 
                     out_riverobs_file=out_ro_file,
                     out_pixc_vector_file=out_pcv_file, 
                     config=config1, delete=delete)
    simple_rivertile(pixc_file=pixc_file_gdem, 
                     out_riverobs_file=out_ro_file_gdem,
                     out_pixc_vector_file=out_pcv_file_gdem, 
                     config=config2, delete=delete)
    simple_rivertile(pixc_file=pixc_file_gdem, 
                     out_riverobs_file=out_ro_file_gdem_dil1,
                     out_pixc_vector_file=out_pcv_file_gdem_dil1, 
                     config=config3, delete=delete)
    simple_rivertile(pixc_file=pixc_file_gdem, 
                     out_riverobs_file=out_ro_file_gdem_dil2,
                     out_pixc_vector_file=out_pcv_file_gdem_dil2, 
                     config=config4, delete=delete)
    simple_rivertile(pixc_file=pixc_file_gdem, 
                     out_riverobs_file=out_ro_file_gdem_dil3,
                     out_pixc_vector_file=out_pcv_file_gdem_dil3, 
                     config=config5, delete=delete)
    simple_rivertile(pixc_file=pixc_file_gdem, 
                     out_riverobs_file=out_ro_file_gdem_dil4,
                     out_pixc_vector_file=out_pcv_file_gdem_dil4, 
                     config=config6, delete=delete)

def check_make_fake_pixc(fake_pixc_name, indir):
    if (os.path.isfile(fake_pixc_name)):
        return
    inpath = os.path.abspath(os.path.expandvars(indir))
    in_pixc = inpath + '/pixel_cloud.nc'
    get_gdem_pixc(inpath, out_pixc = fake_pixc_name)

def main():
    print("running!")
    parser = argparse.ArgumentParser()
    parser.add_argument('run_csv', type=str, 
        help='csv file with run info')
    parser.add_argument('--delete', help='delete and rewrite if existing?')
    
    args = parser.parse_args()
    
    # read the csv
    rundf = pandas.read_csv(args.run_csv)
    
    # For fake pixel clouds--unique combinations of case, flow, pass
    unqdf = rundf[['case', 'pass', 'bndry_cond']].drop_duplicates()
    unqdf['fake_ind'] = [str(x) for x in range(1, len(unqdf) + 1)]
    rundf = rundf.merge(unqdf, on=['pass','bndry_cond','case'], how='left')
    
    # iterate over rows of data frame
    for index, row in rundf.iterrows():
        fakefile='fake_pixc' + row['fake_ind'] + '.nc'
        # if fake pixc exists, use it--otherwise make it. 
        check_make_fake_pixc(fakefile, row['indir'])
                
        rorun(outdir=row['outdir'], indir=row['indir'], priordb=row['priordb'], 
              pixc_file_gdem=fakefile, delete=args.delete)
              
        shutil.copy(fakefile, row['outdir'] + '/fake_pixc.nc')
    
    # cleanup (fake pixel clouds are copied into indiv. directories)
    for index, row in unqdf.iterrows():
        fakefile='fake_pixc' + row['fake_ind'] + '.nc'
        os.remove(fakefile)

if  __name__ == "__main__":
    main()
