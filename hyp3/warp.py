#
# %%
from pathlib import Path
from dateutil.parser import parse as parse_date
import datetime
import asf_search as asf
import pandas as pd
import hyp3_sdk as sdk
from pathlib import Path
from typing import List, Union

#from osgeo import gdal # Import "osgeo" could not be resolved
from osgeo import gdal, osr
#import gdal 
import numpy as np
import shapely 
import matplotlib.pyplot as plt
from osgeo import osr
import matplotlib.ticker as ticker
from pyproj import Proj, transform, CRS, Transformer


def get_epsg(file_path): 
        dataset = gdal.Open(file_path)
        wkt_crs = dataset.GetProjection()
        #print(f"{wkt_crs}")

        # Optional: Parse it into a spatial reference object
        srs = osr.SpatialReference()
        srs.ImportFromWkt(wkt_crs)

        #wkt = dataset.GetProjection()

        # Try getting the EPSG code
        epsg = srs.GetAuthorityCode(None)
        #print(f"epsg: {epsg} wkt_crs {wkt_crs} {file_path}")
        
        return epsg


def clip_hyp3_products_to_common_overlap(data_dir: Union[str, Path], overlap: List[float],epsgAOI) -> None:
    """Clip all GeoTIFF files to their common overlap
    
    Args:
        data_dir:
            directory containing the GeoTIFF files to clip
        overlap:
            a list of the upper-left x, upper-left y, lower-right-x, and lower-right y
            corner coordinates of the common overlap
    Returns: None
    """

    # Define bounding box in target EPSG coordinates: (minX, minY, maxX, maxY)
    #output_bounds = (500000, 4700000, 510000, 4710000)
    
    # Transform bounds to target CRS (e.g., EPSG:32616)
    # transformer = Transformer.from_crs("EPSG:4326", "EPSG:32616", always_xy=True)
    # xmin_t, ymin_t = transformer.transform(xmin, ymin)
    # xmax_t, ymax_t = transformer.transform(xmax, ymax)

    output_bounds = (overlap[0], overlap[3], overlap[2], overlap[1])

    # 2025/06/06 add los_rdr in hopes that it contains bperp info
    # 2025/06/10 add _wrapped_phase.tif 
    files_for_mintpy = ['_water_mask.tif', '_corr.tif', '_unw_phase.tif', '_dem.tif', '_lv_theta.tif', '_lv_phi.tif', '_los_rdr', '_wrapped_phase.tif']

    
    NODATA_VALUE=0
    for extension in files_for_mintpy:

        for file in data_dir.rglob(f'*{extension}'):
            dst_file = file.parent / f'{file.stem}_clipped{file.suffix}'
            # file.name → full file name with extension (e.g., "example.txt")
            # file.stem → file name without extension (e.g., "example")
            # file.suffix → extension only (e.g., ".txt")
            epsgTIF1=get_epsg(file)
            print(f"Warping EPSG from {epsgTIF1} to {epsgAOI} on {file.name} to {dst_file.name}")
            gdal.Warp(srcDSOrSrcDSTab=str(file), 
                      destNameOrDestDS=str(dst_file), 
                      dstSRS=f"EPSG:{epsgAOI}", 
                      outputBounds=output_bounds, 
                      srcNodata = NODATA_VALUE,
                      dstNodata = NODATA_VALUE,
                      )
    
    return




# set up directories
project_name = 'mintpy56'
work_dir = Path.cwd() 
data_dir = work_dir / 'data'
# data_dir.mkdir(parents=True, exist_ok=True)


print(f'data_dir is {data_dir}')

print(f'data_dir is {data_dir}')
file_list = data_dir.glob('*/*_dem.tif')

epsgTIFs = [get_epsg(file_path) for file_path in file_list]

print(f"{epsgTIFs}")

epsgTIF1=np.unique(epsgTIFs)
if len(epsgTIF1) == 1:
    print(f"epsgTIF1 is {epsgTIF1}")
    
else:
    print(f"ERROR TIF files do not all have the same EPSG codes. {len(epsgTIF1)}")   
    raise Exception

# larger SANEM
epsgAOI=32611 # UTM Zone 11 
#bBoxAOI = [291074.4825013202, 4480500.202558111, 298595.532410652, 4469090.405787393] 
# widen eastward to include GPS station GARL
# Eref =     300196.97
# Nref =    4476704.85

bBoxAOI = [291.E3, 4480.E3, 301.E3, 4470.E3] 

print(f"bBoxAOI is {bBoxAOI}")
clip_hyp3_products_to_common_overlap(data_dir, bBoxAOI, epsgAOI)


