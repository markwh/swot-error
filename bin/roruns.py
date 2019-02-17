#!/usr/bin/env python
# Does RiverObs runs and puts the results in a tidy directory

import argparse
import os
import glob
import pandas

print("external packages imported!")
import SWOTRiver
import RDF
import fake_pixc_from_gdem
import L2PIXCVector

def get_config(file = './config/ro-config.rdf', 
            priordb = None,
            gdem = False):
    config = RDF.RDF()
    config.rdfParse(file)
    config = dict(config)
    
    if priordb is not None:
        config['reach_db_path'] = priordb
    
    if gdem:
        config['class_list'] = '[1]'
        config['use_fractional_inundation'] = '[False]'
        config['use_segmentation'] = '[True]'
        config['use_heights'] = '[True]'
    return config


def simple_rivertile(pixc_file, out_riverobs_file,
                     out_pixc_vector_file, config):
    """Simplified swot_pixc2rivertile funciton. 
    
    Largely copy-pasted from Alex's script. 
    """
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

def get_gdem_pixc(indir):
    gdem_file = glob.glob(indir + '/gdem_truth*.nc')
    gdem_pixc_file = 'fake_pixel_cloud.nc'
    fake_pixc_from_gdem.fake_pixc_from_gdem(
        gdem_file, pixc_file, gdem_pixc_file)

def rodryrun(outdir, indir, priordb, force = False):
    print("out: ", outdir)
    print("in: ", indir)
    print("prior: ", priordb)

def rorun(outdir, indir, priordb, force = False):
    """Do a single row's 2 riverobs runs."""
    outpath = os.path.abspath(outdir)
    inpath = os.path.abspath(indir)
    pixc_file = inpath + '/pixel_cloud.nc'
    gdem_file = inpath + '/gdem'
    pixc_file_gdem = get_gdem_pixc(indir)
    
    priorpath = os.path.abspath(priordb)
    print("rorun")
    
    # Create directory if necessary
    try: 
        os.makedirs(outpath)
    except FileExistsError:
        # directory exists
        pass
    
    out_ro_file = outpath + 'rt.nc'
    out_pcv_file = outpath + 'pcv.nc'
    out_ro_file_gdem = outpath + 'rt_gdem.nc'
    out_pcv_file_gdem = outpath + 'pcv_gdem.nc'
    
    config1 = get_config(priordb=priorpath, gdem=False)
    config2 = get_config(priordb=priorpath, gdem=True)
    
    # do 2 separate runs--with and without gdem. 
    simple_rivertile(pixc_file=pixc_file, 
                     out_riverobs_file=out_ro_file,
                     out_pixc_vector_file=out_pcv_file, 
                     config=config1)
                     
    simple_rivertile(pixc_file=pixc_file_gdem, 
                     out_riverobs_file=out_ro_file_gdem,
                     out_pixc_vector_file=out_pcv_file_gdem, 
                     config=config2)

def main():
    print("running!")
    parser = argparse.ArgumentParser()
    parser.add_argument('run_csv', type=str, 
        help='csv file with run info')
    parser.add_argument('--force', help='force run to overwrite existing')
    
    args = parser.parse_args()
    print(args)
    print(type(args))
    print(args.run_csv)
    
    # read csv 
    rundf = pandas.read_csv(args.run_csv)
    
    # iterate over rows of data frame
    for index, row in rundf.iterrows():
        rodryrun(row['outdir'], row['indir'], row['priordb'])


if  __name__ == "__main__":
    main()
