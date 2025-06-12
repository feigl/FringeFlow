# %% [markdown]
# #### Select and create InSAR interferograms with ASF Search 
# version 1 look 
# cut pairs to area of interest, not overlapIntersect
# do not omit seasons
# short time spans only
#
# 2025/05/21 make small test case to debug pyaps
# 2025/06/06 use UTM zones consistently
# 2025/06/09 try to generalize

# %% [markdown]
#  #### 0. Initial Setup
#
# To run this notebook, you'll need a conda environment with the required dependencies. You can set up a new environment (recommended) and run the jupyter server like:
# ```shell
# mamba create --name hyp3-mintpy "python>=3.10" "asf_search>=7.0.0" hyp3_sdk "mintpy>=1.5.2" pandas jupyter ipympl jupytext gdal proj  --channel conda-forge --yes
# ```
#
# mamba run -n hyp3kf jupytext --to py hyp3_insar_stack_for_ts_v1.ipynb
#
# To run in VS Code, then use command palette to do the following:
#     Clear Workspace Interpreter Setting
#     Select interpreter
#         Type interpreter
#             
#    ~/miniforge3/envs/hyp3-mintpy/bin/python

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
import matplotlib.ticker as ticker
from pyproj import Proj, transform, CRS, Transformer
import os
import argparse
import re
from dateutil.parser import parse as parse_date
import datetime
import sys








# %%
def get_site_dims(sitecode5):
    """
    Return bounding box and UTM limits from site_dims.txt for given 5-character site code.
    Equivalent to MATLAB function by Kurt Feigl (2021/10/18).
    """
    home = os.environ.get('HOME')
    fname = os.path.join(home, 'siteinfo', 'site_dims.txt')

    LIMITS = {}
    try:
        with open(fname, 'rt') as fid:
            lines = fid.readlines()

        i = 0
        while i < len(lines):
            tline = lines[i].strip()
            if len(tline) == 6 and ':' in tline and tline[:5].lower() == sitecode5.lower():
                # Found matching site
                if i + 3 >= len(lines):
                    raise ValueError("Insufficient lines after match in file.")

                # Line 1: lat/lon
                latlon_line = lines[i+1].strip().replace('-R', '').replace('/', ',')
                lonMin, lonMax, latMin, latMax = map(float, latlon_line.split(','))
                LIMITS['lonMin'] = lonMin
                LIMITS['lonMax'] = lonMax
                LIMITS['latMin'] = latMin
                LIMITS['latMax'] = latMax

                # Line 2: UTM
                utm_line = lines[i+2].strip().replace('-R', '').replace('/', ',')
                Emin, Emax, Nmin, Nmax = map(float, utm_line.split(','))
                LIMITS['Emin'] = Emin
                LIMITS['Emax'] = Emax
                LIMITS['Nmin'] = Nmin
                LIMITS['Nmax'] = Nmax

                # Line 3: UTM zone
                utm_zone_line = lines[i+3].strip()
                LIMITS['UTMzone'] = int(utm_zone_line)
                break

            i += 1

        if not LIMITS:
            raise ValueError(f"Site code {sitecode5} not found in {fname}")

        return LIMITS

    except FileNotFoundError:
        raise FileNotFoundError(f"Could not open file named {fname}")




# %%
# function to calculate the day of the year

def day_of_year(date):
    #print(f"date is {date}")
    #print(f'type of date is {type(date)}')
    if type(date) == type(datetime.datetime(2024,8,29)):
        doy = date - datetime.datetime(date.year, 1, 1,tzinfo=date.tzinfo) + datetime.timedelta(days=1)
    elif type(date) == type('hello'):
        date1=parse_date(date)
        doy = date1 - datetime.datetime(date1.year, 1, 1, tzinfo=date1.tzinfo) + datetime.timedelta(days=1)
    elif type(date) == 'pandas.core.series.Series':
        nDates=len(date)
        print(f"nDates is {nDates}")
    
    else:
        print(f"Error")
        doy=None
        raise Exception
    return doy.days

def plot_lola(dateStr0,dateStr1,AOIlola,lonCenter,latCenter,work_dir):
    # Plot the rectangle
    #plt.figure()
    fig, ax = plt.subplots()
    plt.plot([en[0] for en in AOIlola], [EN[1] for EN in AOIlola], marker='o', linestyle='-')
    plt.plot(lonCenter,latCenter,marker='*',color='magenta',markersize=24)
    #plt.fill([EN[0] for EN in AOIlola], [EN[1] for EN in AOIlola], alpha=0.2, color='blue')
    fig.suptitle(f"{work_dir}")
    plt.title(f"{dateStr0} to {dateStr1}")
    plt.xlabel("Longitude",fontsize=9)
    plt.ylabel("Latitude",fontsize=9)
    plt.grid(True)
    # Format tick labels to show 3 decimal places
    ax.xaxis.set_major_formatter(ticker.FormatStrFormatter('%.2f'))
    ax.yaxis.set_major_formatter(ticker.FormatStrFormatter('%.2f'))
    plt.xticks(fontsize=9)
    plt.yticks(fontsize=9)

    mean_lat = np.radians(np.mean([lola[1] for lola in AOIlola]))
    aspect_ratio = 1 / np.cos(mean_lat)

    ax.set_aspect(aspect_ratio)
    fig.savefig('search1lola.png',dpi=600)
    # Display the plot
    #fig.show()
    plt.show(block=False)
    
    return


# %% [markdown]
# ### 3.1 Subset all GeoTIFFs to their common overlapIntersect

# %%
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



# %%
def clip_hyp3_products_to_common_overlap(data_dir: Union[str, Path], overlap: List[float]) -> None:
    """Clip all GeoTIFF files to their common overlap
    
    Args:
        data_dir:
            directory containing the GeoTIFF files to clip
        overlap:
            a list of the upper-left x, upper-left y, lower-right-x, and lower-tight y
            corner coordinates of the common overlap
    Returns: None
    """

    # 2025/06/11 add two more files
    files_for_mintpy = ['_water_mask.tif',
                        '_corr.tif',
                        '_conncomp.tif',
                        '_unw_phase.tif',
                        '_dem.tif',
                        '_lv_theta.tif',
                        '_lv_phi.tif'
                        '_los_rdr', 
                        '_wrapped_phase.tif']

    for extension in files_for_mintpy:

        for file in data_dir.rglob(f'*{extension}'):

            dst_file = file.parent / f'{file.stem}_clipped{file.suffix}'

            gdal.Translate(destName=str(dst_file), srcDS=str(file), projWin=overlap)
# %%
def find_zip_files(directory):
    # Compile the regex pattern to match .zip files
    pattern = re.compile(r'.*\.zip$')

    # List all files in the directory
    all_files = os.listdir(directory)

    # Filter and return files that match the pattern
    zip_files = [f for f in all_files if pattern.match(f)]
    return zip_files



# %%
def warp_hyp3_products_to_common_overlap(data_dir: Union[str, Path], overlap: List[float],epsgAOI) -> None:
    """Warp all GeoTIFF files to their common overlap
    
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
                      dstNodata=0, 
                      )
    
    return


# %%
def plot_utm(dateStr0,dateStr1,AOIlola,UTMzone,work_dir):

    # Create a projection object for UTM zone (you need to specify the zone)
    #UTMprojectionFunction = Proj(proj="utm", zone=11, ellps="WGS84", south=False)
    UTMprojectionFunction = Proj(proj="utm", zone=UTMzone, ellps="WGS84", south=False)
    print(f"{UTMprojectionFunction}")

    # Convert to CRS and get EPSG code
    crsAOI = CRS.from_proj4(UTMprojectionFunction.srs)
    epsgAOI = crsAOI.to_epsg()
    print(f"for AOI: EPSG code: {epsgAOI} CRS code {crsAOI} ")


    # Project the lat/lon coordinates into UTM
    AOIutm = [UTMprojectionFunction(lon, lat) for lon, lat in AOIlola]
    #ENcenter = UTMprojectionFunction(lonCenter, latCenter)

    # define the bounding box
    # larger SANEM
    #epsgAOI=32611 # UTM Zone 11 
    #bBoxAOI = [291074.4825013202, 4480500.202558111, 298595.532410652, 4469090.405787393] 
    # widen eastward to include GPS station GARL
    # Eref =     300196.97
    # Nref =    4476704.85

    #bBoxAOI = [291.E3, 4480.E3, 301.E3, 4470.E3] 
    ulx = np.floor(min([corner[0] for corner in AOIutm]))
    uly = np.ceil(max([corner[1] for corner in AOIutm]))
    lrx = np.ceil(max([corner[0] for corner in AOIutm]))
    lry = np.floor(min([corner[1] for corner in AOIutm]))
    bBoxAOI=[ulx, uly, lrx, lry]

    print(f"bBoxAOI is {bBoxAOI}")

    # Plot the UTM rectangle
    #plt.figure()
    fig, ax = plt.subplots()
    plt.plot([EN[0]/1000. for EN in AOIutm], [EN[1]/1000. for EN in AOIutm], marker='o', linestyle='-',label='AOI')
    plt.fill([EN[0]/1000. for EN in AOIutm], [EN[1]/1000. for EN in AOIutm], alpha=0.2, color='blue')
    #plt.plot(ENcenter[0]/1000., ENcenter[1]/1000, marker='*', color='magenta',linestyle=None)
    plt.suptitle(f"{work_dir} \n {dateStr0} to {dateStr1}", fontsize=9)
    plt.title(f"EPSG code: {epsgAOI} \n CRS code {crsAOI}", fontsize=9)
    plt.xlabel("UTM Easting [km]")
    plt.ylabel("UTM Northing [km]")
    # Format tick labels to show 0 decimal places
    ax.xaxis.set_major_formatter(ticker.FormatStrFormatter('%.0f'))
    ax.yaxis.set_major_formatter(ticker.FormatStrFormatter('%.0f'))
    plt.grid(False)
    ax.set_aspect('equal', 'box')
    # Place legend outside to the upper right
    ax.legend(loc='upper left', bbox_to_anchor=(1.05, 1), borderaxespad=0.)
    plt.tight_layout()  # Adjust layout to prevent clipping

    # save the plot, then show it
    plt.savefig('search1utm.png',dpi=600)
    plt.show(block=False)
    
    return [AOIutm,bBoxAOI,epsgAOI,UTMprojectionFunction]


# %%
def main():
    parser = argparse.ArgumentParser(description="Script with debug/--no-debug switch.")
    parser.add_argument("--site", dest="site",     default="BRADY", help="name of site as 5-character upper-case word")
    parser.add_argument("--name", dest="project_name", default="mintpy60", help="label for solution")
    parser.add_argument("--aord", dest="aord",     default="ASCENDING", help="flight direction ASCENDING or DESCENDING")
    parser.add_argument("--t0",   dest="dateStr0", default="2020-01-01", help="start date in format YYYY-MM-DD")
    parser.add_argument("--t1",   dest="dateStr1", default="2020-12-31", help="end   date in format YYYY-MM-DD")
 
    debug_group = parser.add_mutually_exclusive_group()
    debug_group.add_argument('--debug', dest='debug', action='store_true', help="Enable debug mode")
    debug_group.add_argument('--no-debug', dest='debug', action='store_false', help="Disable debug mode")
    parser.set_defaults(debug=False)  # Default is --no-debug

    args = parser.parse_args()

    if args.debug:
        print(f"Debug is on")
    else:
        print("Debug mode is OFF")
        
    return

# %%




# Main logic here
#
## set main controlling parameters here
project_name = 'mintpy62'  # short test case
burstORslc='BURST'
site = 'BRADY'
aord = asf.FLIGHT_DIRECTION.ASCENDING
burstORslc == 'BURST'
dateStr0='2021-01-01'
dateStr1='2021-12-31'
debug=True
minTemporalBaseline = 5      # days
maxTemporalBaseline = 12    # days # must be greater than excluded season
maxPerpendicularBaseline = 10 # meters

## consider season - causes problems
# take whole year
doy1=1
doy2=366
# exclude January and February
#doy1 = day_of_year(parse_date('2023-03-01'))
#doy2 = day_of_year(parse_date('2023-12-31'))
# take Summer only
# doy1 = day_of_year(parse_date('2023-06-01'))
# doy2 = day_of_year(parse_date('2023-08-31'))
season = [doy1,doy2]
# print(f"season is {season}")

# set up directories
if os.path.isdir('/Volumes/feigl/insar'):
    topPath='/Volumes/feigl/insar'
elif os.path.isdir('/data/insar'):
    topPath='/data/insar'
elif os.path.isdir('/t31/insar'):
    topPath='/t31/insar'
else:
    topPath='~/insar'

# working directory
work_dir = Path(topPath) / site / 'SDK' / aord / project_name
work_dir.mkdir(parents=True, exist_ok=True)
print(f"Changing working directory to {work_dir}")  
os.chdir(work_dir)

# data directory
data_dir = work_dir / 'data'
data_dir.mkdir(parents=True, exist_ok=True)
print(f"data_dir is {data_dir}")


# %%
# Use your [NASA Earthdata login](https://urs.earthdata.nasa.gov/) 
# to connect to [ASF HyP3](https://hyp3-docs.asf.alaska.edu/).
#hyp3 = sdk.HyP3(prompt=True)
hyp3 = sdk.HyP3(prompt=False)
#hyp3 =  sdk.HyP3.get_authenticated_session('feigl@wisc.edu')
nCredits0=hyp3.check_credits()
print(f'Number of credits before starting jobs is {nCredits0}')

# %% get coordinates
LIMITS=get_site_dims(site)
print(f"{LIMITS}")
print(f"{LIMITS['lonMin']:12.8f}")
print(f"{LIMITS['UTMzone']}")

if site == 'DCAMP':
    # The DAC is expanded to encompass GVR (78 km2) 
    # -118.3591409949927,38.81917034951293,0 -118.2245378112751,38.82065893511532,0 -118.2251891413302,38.88085324203438,0 -118.3605156707135,38.87935480699949,0 -118.3591409949927,38.81917034951293,0 
    # corner	lon	lat	ground
    # SW	-118.35914099	38.81917035	0
    # B	    -118.22453781	38.82065894	0
    # NE	-118.22518914	38.88085324	0
    # D	    -118.36051567	38.87935481	0
    # mean	-118.29234590	38.85000933	0
    latMin=38.81917035
    latMax=38.88085324
    lonMin=-118.36051567
    lonMax=-118.22453781
    UTMzone=11 # 11 S verified by Google Earth
elif site == 'SANEM':
    # original AOI
    #  grep -A3 sanem ~/siteinfo/site_dims.txt  
    # sanem:
    # -R-119.46/-119.375/40.348/40.449
    # -R291074.48226/298595.53221/4469090.38971/4480500.18609
    # 11
    # latMin=40.348
    # latMax=40.449
    # lonMin=-119.46
    # lonMax=-119.375 
    
    # larger AOI from /Users/feigl/siteinfo/sanem/AOIforSANEM2025.kml  
    # -119.5086551479411,40.3051742449493,0
    # -119.3250213982107,40.30569311996287,0
    # -119.3270788642407,40.50172708513533,0
    # -119.5083119649335,40.5004502253031,0
    # -119.5086551479411,40.3051742449493,0
    latMin=40.30517424494930
    latMax=40.50172708513533
    lonMin=-119.5086551479411
    lonMax=-119.3250213982107
    UTMzone=11      # 2025/06/05  verified by Google Earth
elif site == 'MCGIN':
    UTMzone=11 # 11 S verified by Google Earth
    assert False
elif site == 'BRADY':
    UTMzone=LIMITS['UTMzone']
    LIMITS=get_site_dims(site)
    # 
    lonMin=LIMITS['lonMin'] 
    lonMax=LIMITS['lonMax'] 
    latMin=LIMITS['latMin'] 
    latMax=LIMITS['latMax']
    # # expand by 10 km - fails
    # lonMin=LIMITS['lonMin'] - 10/111.
    # lonMax=LIMITS['lonMax'] + 10/111.
    # latMin=LIMITS['latMin'] - 10/111.
    # latMax=LIMITS['latMax'] + 10/111.
    #print(f"{LIMITS['lonMin']:12.8f}")
    
else:
    print(f"WARNING unknown site {site}")
    UTMzone=LIMITS['UTMzone']
    LIMITS=get_site_dims(site)
    lonMin=LIMITS['lonMin']
    lonMax=LIMITS['lonMax']
    latMin=LIMITS['latMin']
    latMax=LIMITS['latMax']

print(f"UTMzone is {UTMzone}")   
lonCenter=(lonMin + lonMax)/2
latCenter=(latMin + latMax)/2
# format is intersectsWith='POINT(-119.543 37.925)'
centerAOIWKT=f'POINT({lonCenter} {latCenter})'
print(f"centerAOIWKT is {centerAOIWKT}")

# Define the four corners
AOIlola = [
    [lonMin, latMin],  # Bottom-left corner
    [lonMax, latMin],  # Bottom-right corner
    [lonMax, latMax],  # Top-right corner
    [lonMin, latMax],  # Top-left corner
    [lonMin, latMin]   # Close the loop by returning to bottom-left
]

# make plots
plot_lola(dateStr0,dateStr1,AOIlola,lonCenter,latCenter,work_dir)
AOIutm,bBoxAOI,epsgAOI,UTMprojectionFunction = plot_utm(dateStr0,dateStr1,AOIlola,UTMzone,work_dir)


if debug:
    print("Debug mode is ON. Continuing bravely onward.")
else:
    print("Debug mode is OFF. Continuing bravely onward.")  
    #sys.exit(f"Debug mode is off. Exiting here.")
    

# %%
print(f"timeout is now {asf.constants.INTERNAL.CMR_TIMEOUT} seconds")
asf.constants.INTERNAL.CMR_TIMEOUT=120
print(f"timeout is now {asf.constants.INTERNAL.CMR_TIMEOUT}: seconds")

if burstORslc == 'BURST':
    processingLevel=asf.PRODUCT_TYPE.BURST
# elif burstORslc == 'MULTIBURST':
#     processingLevel=asf.PRODUCT_TYPE.BURST
elif burstORslc == 'SLC':
    processingLevel=asf.PRODUCT_TYPE.SLC
else:
    assert False # throw an error
ProductsFound = asf.geo_search(
        platform=asf.PLATFORM.SENTINEL1,
        intersectsWith=centerAOIWKT,
        start=dateStr0,
        end  =dateStr1,        
        processingLevel=processingLevel,
        polarization=asf.POLARIZATION.VV, 
        beamMode=asf.BEAMMODE.IW,
        flightDirection=aord,
    )
        # season=season,


nProducts=len(ProductsFound)
print(f'nProducts = {nProducts}')


# make sure scene or burst overlapUnions with all 4 corners of the AOI
point= shapely.wkt.loads(centerAOIWKT)

# Plot the AOI rectangle in lon, lat
#print(f'{AOIlola}')
#print(f'{coordinates}')
# plt.figure()
# plt.plot([point[0] for point in AOIlola], [point[1] for point in AOIlola], marker='o', linestyle='-')
# plt.fill([point[0] for point in AOIlola], [point[1] for point in AOIlola], alpha=0.2, color='blue')
# plt.plot(lonCenter,latCenter,marker='*',color='magenta',markersize=12)

for product in ProductsFound: 
    coordsLOLA=product.geometry['coordinates']
    polygon = shapely.Polygon(coordsLOLA[0])
    for corner in AOIlola:
        point = shapely.Point(corner)
    
    # plot the coordinates for this scene
    #plt.plot([point[0] for point in coordsLOLA[0]], [point[1] for point in coordsLOLA[0]], marker='+', linestyle='-')

# plt.suptitle(f"{work_dir}")
# plt.title(f"{dateStr0} to {dateStr1}")
# plt.xlabel("UTM Easting [km]")
# plt.ylabel("UTM Northing [km]")
# # Format tick labels to show 3 decimal places
# #plt.gca().xaxis.set_major_formatter(ticker.FormatStrFormatter('%.3f'))
# #plt.gca().yaxis.set_major_formatter(ticker.FormatStrFormatter('%.3f'))
# plt.grid(False)
# # save the plot, then show it
# plt.savefig('search1utm.png',dpi=600)
# plt.show()

# %%
# map coverage in UTM
# Project the lat/lon coordinates into UTM
AOIutm = [UTMprojectionFunction(lon, lat) for lon, lat in AOIlola]

# #plt.figure()
# fig, ax = plt.subplots()

# plt.plot([point[0]/1000 for point in AOIutm], [point[1]/1000 for point in AOIutm], marker='o', linestyle='-')
# plt.fill([point[0]/1000 for point in AOIutm], [point[1]/1000 for point in AOIutm], alpha=0.2, color='blue',label='AOI')
# #plt.plot(ENcenter[0]/1000,ENcenter[1]/1000,marker='*',color='magenta',markersize=12,label='AOI center')

nKeep=0
nSkip=0
#granulesKept=empty_object = type(granulesFound)()
ProductsKept = empty_object = type(ProductsFound)()
for product in ProductsFound: 
    print(f"{product.properties['sceneName']}")  
    #print(f"{granule.geometry['coordinates'][0][0]}")
    #polygon=shapely.wkt.loads(granule.geometry['coordinates'])
    coordsLOLA=product.geometry['coordinates']
    #print(f'{coordsLOLA}')
    coordsUTM=[UTMprojectionFunction(lola[0],lola[1]) for lola in coordsLOLA[0]]
    
    #print(f'{coordsUTM}')
    polygon = shapely.Polygon(coordsUTM)
    #print(f'{polygon}')

    mKeep=0
    mSkip=0 
    for corner in AOIutm:
        #print(f'{corner}')
        point = shapely.Point(corner)
        #print(f'point is {point}')
        # Check for intersection
        if point.intersects(polygon):
            #print(f"The point intersects the polygon.")
            mKeep=mKeep+1
        else:
            #print(f"The point does not intersect the polygon.")
            mSkip=mSkip+1
            
    #print(f"mKeep = {mKeep} mSkip = {mSkip}")       
    if mKeep >=2:
        nKeep=nKeep+1
        ProductsKept.append(product)
    else:
        nSkip=nSkip+1
    
    # plot the coordinates for this scene
    #plt.plot([point[0]/1000 for point in coordsUTM], [point[1]/1000 for point in coordsUTM], marker='+', linestyle='-')
    #ax.set_aspect('equal', 'box')

# #plt.title(f"{granule.properties['sceneName']}")
# plt.suptitle(f"{work_dir}")
# plt.title(f"{dateStr0} to {dateStr1} nKeep = {nKeep} nSkip = {nSkip}")
# plt.xlabel("UTM Easting [km]")
# plt.ylabel("UTM Northing [km]")
# plt.grid(True)
# plt.savefig('search2.png')
# # Display the plot
# plt.show()

print(f"Number of products found is {len(ProductsFound)}")
print(f"Number of products kept  is {len(ProductsKept)}")
print(f"nKeep  is                   {nKeep}")
#print(f"{granulesKept[0]}")
# for product in ProductsKept:
#     #print(f"{granule.properties['sceneName']}")  
#     # OK  print(f"{product.properties}")  
#     # OK  print(f"{product.properties['burst']}")
#     prop1=product.properties['burst']
#     #print(f"{prop1}")
#     print(f"{prop1['burstIndex']}") 

# %%
print(f'asf.constants.INTERNAL.CMR_TIMEOUT is {asf.constants.INTERNAL.CMR_TIMEOUT} seconds')
asf.constants.INTERNAL.CMR_TIMEOUT=120
print(f'asf.constants.INTERNAL.CMR_TIMEOUT is {asf.constants.INTERNAL.CMR_TIMEOUT} seconds')

# make a stack of epochs
print(f"number of products is {len(ProductsKept)}")
# This will make a stack of ALL possible pairs that use last epoch as reference
EpochsAll = asf.baseline_search.stack_from_product(ProductsKept[-1])
# print(f"{StackAll.Properties.values}")
                                                            
nStackAll = len(EpochsAll)
print(f"nStackAll is {nStackAll}")


# trim list of epochs
t0 = parse_date(dateStr0 + ' 00:00:00Z')
t1 = parse_date(dateStr1 + ' 23:59:59Z')

EpochsSub=empty_object=type(EpochsAll)()
for Epoch0 in EpochsAll:
    #print(f"baseline is {baseline}")
    if ((parse_date(Epoch0.properties['startTime']) >= t0) 
        and (parse_date(Epoch0.properties['stopTime']) <= t1) 
        and Epoch0.properties['perpendicularBaseline'] != None):
        EpochsSub.append(Epoch0)
    
nStackSub=len(EpochsSub)
print(f"nStackSub is {nStackSub}")

# for Epoch0 in EpochsSub:
#     #print(f"{Epoch0.properties}") 
#     print(f"{Epoch0.properties['startTime']} {Epoch0.properties['temporalBaseline']:5d}days {Epoch0.properties['perpendicularBaseline']:10.1f}m {Epoch0.properties['burst']['fullBurstID']}")




# %%
# start building set of pairs

Pairs = set()
# make a set adding to the end
for Epoch0 in EpochsSub:
    #print(f"{Epoch0.properties}") 

    rN=Epoch0.properties['sceneName']             # long name of burst granule
    rt=Epoch0.properties['temporalBaseline']      # days from first epoch for reference
    rB=Epoch0.properties['perpendicularBaseline'] # meters from first epoch for reference
    rd=day_of_year(parse_date(Epoch0.properties['startTime'])) # day of year 
    rS=Epoch0.properties['burst']['subswath']
    ri=Epoch0.properties['burst']['burstIndex']           # 5, 6, 7
    rF=Epoch0.properties['burst']['fullBurstID']
    
    for Epoch1 in EpochsSub:
        sN=Epoch1.properties['sceneName']             # long name of burst granule
        st=Epoch1.properties['temporalBaseline']      # days from first epoch for reference
        sB=Epoch1.properties['perpendicularBaseline'] # meters from first epoch for reference
        sd=day_of_year(parse_date(Epoch1.properties['startTime'])) # day of year 
        sS=Epoch1.properties['burst']['subswath']   # 'IW1' 'IW2' or 'IW3'
        si=Epoch1.properties['burst']['burstIndex']           # 5, 6, 7
        sF=Epoch1.properties['burst']['fullBurstID']
        
    
        if ((sN != rN) and (si == ri) and (sS == rS) and (sF == rF)
            and (abs(sB - rB) < maxPerpendicularBaseline)
            and (st - rt <= maxTemporalBaseline)
            and (st - rt >  minTemporalBaseline)
            and (rd >= season[0])
            and (rd <= season[1])
            ):
            print(f"{rN}, {sN}, {abs(sB - rB):10.1f}m, {(st-rt):5d}days {ri}, {rS}, {rF}")
            Pairs.add((rN,sN) )
            

    
nPairs=len(Pairs)
print(f'number of pairs nPairs = {nPairs}')





# %%
costs=hyp3.costs()
print(f"costs is of type {type(costs)}")
print(f"{costs}")
for cost in costs:
    print(f"{cost}")
#     for p in cost:
#         print(p,end="\n")
#     print()
    




# %% [markdown]
#     # The number of looks drives the resolution and pixel spacing of the output products. 
#     # Selecting 10x2 looks will yield larger products with 80 m resolution and pixel spacing of 40 m. 
#     # Selecting 20x4 looks reduces the resolution to 160 m and reduces the size of the products (roughly 1/4 the size of 10x2 look products), with a pixel spacing of 80 m. 
#     # The default is 20x4 looks.
#     # 
#     # Modifying looks does not change the cost!
#     # 
#     # 


# %%
#help(sdk.Batch)
jobName=project_name
print(f'Preparing insar burst jobs with name {project_name}')
nCredits0 = hyp3.check_credits()
print(f'nCredits0 = {nCredits0}')
#looks='20x4'
looks='10x2'
jobs = sdk.Batch()
nJobs=0
for Epoch0, Epoch1 in Pairs:
    nJobs=nJobs+1
    
    #jobName="%s_job%02d" % (project_name, nJobs)
    # new in hyp3_sdk v7.4.0 API Reference
    #https://hyp3-docs.asf.alaska.edu/using/sdk_api/#hyp3_sdk.HyP3.prepare_insar_isce_multi_burst_job
    print(f"{nJobs:5d} : {Epoch0} to {Epoch1}")
    if burstORslc == 'BURST':
        job=hyp3.prepare_insar_isce_burst_job(Epoch0, Epoch1, 
            name=jobName, 
            apply_water_mask=True,
            looks=looks)
        # jobs+=hyp3.submit_insar_isce_burst_job(Epoch0, Epoch1, 
        #     name=jobName, 
        #     apply_water_mask=True,
        #     looks=looks)
        costFor1Job=1
    elif burstORslc == 'MULTIBURST':     
            #     prepare_insar_isce_multi_burst_job(reference, secondary, name=None, apply_water_mask=False, looks='20x4') classmethod ¶
            # Prepare an InSAR ISCE multi burst job.

            # Parameters:

            # Name	Type	Description	Default
            # reference	list[str]	A list of reference granules (scenes) to use	required
            # secondary	list[str]	A list of secondary granules (scenes) to use	required
            # name	str | None	A name for the job	None
            # apply_water_mask	bool	Sets pixels over coastal waters and large inland waterbodies as invalid for phase unwrapping	False
            # looks	Literal['20x4', '10x2', '5x1']	Number of looks to take in range and azimuth
        job=prepare_insar_isce_multi_burst_job(Epoch0, Epoch1, 
            name=jobName, 
            looks=looks)
        costFor1Job=1
    elif burstORslc == 'SLC':
        job=hyp3.prepare_insar_job(Epoch0, Epoch1, 
                                name=jobName, 
                                looks=looks, 
                                include_look_vectors=True, 
                                include_inc_map=True, 
                                include_dem=True, 
                                include_wrapped_phase=True, 
                                apply_water_mask=False,
                                include_displacement_maps=True, 
                                phase_filter_parameter=0.6) 
        costFor1Job=15
    else:
        assert False # throw error
    
    jobs+=hyp3.submit_prepared_jobs(job)
        
print(f'nJobs is {nJobs}')
costEstimate=nJobs*costFor1Job # TODO use cost value from table, type of job and possibly number of looks
print(f'costEstimate is {costEstimate}')


# %%
jobs = hyp3.watch(jobs)
nCredits1 = hyp3.check_credits()
print(f'nCredits1 = {nCredits1}')
nCreditsUsed=nCredits1-nCredits0
print(f'nCreditsUsed = {nCreditsUsed}')
#print(f'costEstimate is {costEstimate}')

# %%
jobs = hyp3.find_jobs(name=project_name)

# %%
# download 
insar_products = jobs.download_files(data_dir)
print(f'data_dir is {data_dir}')
insar_products = data_dir.glob('*.zip')
print(f'{insar_products}')



# %%
insar_products = [sdk.util.extract_zipped_product(ii,delete=False) for ii in insar_products]
        
    





# %%
# from https://github.com/ASFHyP3/hyp3-docs/blob/main/docs/tutorials/hyp3_isce2_burst_stack_for_ts_analysis.ipynb
def get_common_overlap_intersect(file_list: List[Union[str, Path]]) -> List[float]:
    """Get the common overlap of  a list of GeoTIFF files

    Arg:
        file_list: a list of GeoTIFF files

    Returns:
         [ulx, uly, lrx, lry], the upper-left x, upper-left y, lower-right x, and lower-right y
         corner coordinates of the common overlap
    """
    gdal.UseExceptions()
    corners = [gdal.Info(str(dem), format='json')['cornerCoordinates'] for dem in file_list]

    ulx = max(corner['upperLeft'][0] for corner in corners)
    uly = min(corner['upperLeft'][1] for corner in corners)
    lrx = min(corner['lowerRight'][0] for corner in corners)
    lry = max(corner['lowerRight'][1] for corner in corners)
    return [ulx, uly, lrx, lry]


# %%
def get_common_overlap_union(file_list: List[Union[str, Path]]) -> List[float]:
    """Get the common overlap of  a list of GeoTIFF files

    Arg:
        file_list: a list of GeoTIFF files

    Returns:
         [ulx, uly, lrx, lry], the upper-left x, upper-left y, lower-right x, and lower-right y
         corner coordinates of the common overlap
         
         from https://github.com/ASFHyP3/hyp3-docs/blob/main/docs/tutorials/hyp3_isce2_burst_stack_for_ts_analysis.ipynb
         
         # updated 2025/05/17
    """

    gdal.UseExceptions()

    #print(f"file_list is {file_list}")
    
    # for dem in file_list[0]:
    #     info = gdal.Info(str(dem), format='json') 
    #     #print(f"dem is {dem} info is {info}")
    #     #'coordinateSystem': {'wkt': 'PROJCRS["WGS 84 / UTM zone 10N",\n
    #     print(f" {info['coordinateSystem']['wkt']}")
    #     #print(f" {info['coordinateSystem']['wkt']['PROJCRS']}")

    corners = [gdal.Info(str(dem), format='json')['cornerCoordinates'] for dem in file_list]
    
    ulx = min(corner['upperLeft'][0] for corner in corners)
    uly = max(corner['upperLeft'][1] for corner in corners)
    lrx = max(corner['lowerRight'][0] for corner in corners)
    lry = min(corner['lowerRight'][1] for corner in corners)
    
    
    print(f"{[ulx, uly, lrx, lry]}")
    
         
    return [ulx, uly, lrx, lry]


# %%
gdal.UseExceptions()
print(f'data_dir is {data_dir}')
file_list = data_dir.glob('*/*_dem.tif')

epsgTIFs = [get_epsg(file_path) for file_path in file_list]
print(f"{epsgTIFs}")

epsgTIF1=np.unique(epsgTIFs)
print(f"{epsgTIF1}")

print(f"in EPSG {epsgAOI}  bBoxAOI is     {bBoxAOI}")
file_list = data_dir.glob('*/*_dem.tif')
bBoxUnion = get_common_overlap_union(file_list)
print(f"in EPSG {epsgTIF1} bBoxUnion is     {bBoxUnion}")
file_list = data_dir.glob('*/*_dem.tif')
bBoxIntersect = get_common_overlap_intersect(file_list)
print(f"in EPSG {epsgTIF1} bBoxIntersect is {bBoxIntersect}")

if len(epsgTIF1) == 1:
    epsgTIF1=int(epsgTIF1[0]) # convert list to integer
    print(f"epsgTIF1 is {epsgTIF1}")  
    # print(f"EPSG codes in TIF files {epsgTIF1} matches EPSG code in AOI {epsgAOI}. Starting to clip TIF files to Union...")
    # clip_hyp3_products_to_common_overlap(data_dir, bBoxUnion)
    # take everything
    # print(f"EPSG codes in TIF files {epsgTIF1} matches EPSG code in AOI {epsgAOI}. Starting to clip TIF files to Intersection...")
    # clip_hyp3_products_to_common_overlap(data_dir, bBoxIntersect)
    # leads to error downstream ::
    # ValueError: could not broadcast input array from shape (367,287) into shape (1004,2647)
 
else:
    print(f"ERROR TIF files do not all have the same EPSG codes. {len(epsgTIF1)}") 
    sys.exit(f"Exiting here.")  
    raise Exception

print(f"epsgAOI is {epsgAOI}")

if epsgTIF1 == epsgAOI:
    print(f"EPSG codes in TIF files {epsgTIF1} matches EPSG code in AOI {epsgAOI}. Starting to clip TIF files...")
    clip_hyp3_products_to_common_overlap(data_dir, bBoxAOI)
else:
    print(f"EPSG codes in TIF files {epsgTIF1} does NOT match EPSG code in AOI {epsgAOI}. Starting to warp TIF files slowly.... ")
    warp_hyp3_products_to_common_overlap(data_dir, bBoxAOI, epsgAOI)
    
print(f"Done with TIF files.")

# %%
mintpy_config = work_dir / 'mintpy_config.txt'
mintpy_config.write_text(
f"""
mintpy.load.processor        = hyp3
##---------interferogram datasets:
mintpy.load.unwFile          = {data_dir}/*/*_unw_phase_clipped.tif
mintpy.load.corFile          = {data_dir}/*/*_corr_clipped.tif
mintpy.load.connCompFile     = {data_dir}/*/*_conncomp_clipped.tif
##---------geometry datasets:
mintpy.load.demFile          = {data_dir}/*/*_dem_clipped.tif
mintpy.load.incAngleFile     = {data_dir}/*/*_lv_theta_clipped.tif
mintpy.load.azAngleFile      = {data_dir}/*/*_lv_phi_clipped.tif
mintpy.load.waterMaskFile    = {data_dir}/*/*_water_mask_clipped.tif
mintpy.troposphericDelay.method = no
##---------misc:
mintpy.plot = no
mintpy.network.coherenceBased = no
""")


# %%
# #!smallbaselineApp.py --dir {work_dir} {mintpy_config}
# # !mamba run -n mintpy smallbaselineApp.py --dir {work_dir} {mintpy_config}
# # %matplotlib widget
# from mintpy.cli import view, tsview
# view.main([f'{work_dir}/velocity.h5'])
# tsview.main([f'{work_dir}/timeseries.h5'])

# # rm -rf inputs pic *.h5
# mamba run -n mintpy smallbaselineApp.py ${runname}.cfg > ${runname}.out 2> ${runname}.err &

# ValueError: Invalid NaN value found in the following kept pairs for Bperp or coherence! 
#         They likely have issues, check them and maybe exclude them in your network.
#         ['20220910_20221016']
# # ls data -d | grep 20220910 | grep 20221016
# ls: -d: No such file or directory
# S1_135553_IW2_20220910_20221016_VV_INT40_6D3B
# S1_135553_IW2_20220910_20221016_VV_INT40_6D3B.zip
# (base) brady:mintpy61 feigl$ mkdir data_bad
# (base) brady:mintpy61 feigl$ mv data/S1_135553_IW2_20220910_20221016_VV_INT40_6D3B data_bad

