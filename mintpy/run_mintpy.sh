#!/bin/bash 
## 2021/08/05 Kurt Feigl

# Run epochs for MINTPY
bname=`basename $0`
if [[  ( "$#" -eq 1)  ]]; then
   export CFG=$1
   export STEP="load_data"  
elif [[  ( "$#" -eq 2)  ]]; then
  export CFG=$1
  export STEP=$2
else
    echo "$bname will run mintpy "
    echo "usage:   $bname config.cfg step_name"
    echo "example: $bname FORGE_20210719_ERA5.cfg load_data"
    echo "example: $bname FORGE_20210719_ERA5.cfg quick_overview"
    exit -1
#   ['load_data', 'modify_network', 'reference_point', 'quick_overview', 'correct_unwrap_error']
#   ['invert_network', 'correct_LOD', 'correct_SET', 'correct_troposphere', 'deramp', 'correct_topography']
#   ['residual_RMS', 'reference_date', 'velocity', 'geocode', 'google_earth', 'hdfeos5']
fi

echo "Config file CFG is $CFG"
echo "STEP is ${STEP}"

# clean start
rm -rf pic isce.log

# TODO test on STEP
#rm -rf inputs

# copy keys for ERA PYAPS
if [ -f ../model.cfg ]; then
   cp -v ../model.cfg /home/ops/PyAPS/pyaps3/model.cfg
fi
if [ -f model.cfg ]; then
   cp -v model.cfg /home/ops/PyAPS/pyaps3/model.cfg
fi

# make a directory for storing weather data
if [ ! -d ${PWD}/../WEATHER ]; then
   mkdir -p "${PWD}/../WEATHER"
fi
export WEATHER_DIR="${PWD}/../WEATHER"

# # Add meta data to configuration file
# head SANEM_T144f_askja.cfg 
# ########## 1. load_data
# ##---------add attributes manually
# ## MintPy requires attributes listed at: https://mintpy.readthedocs.io/en/latest/api/attributes/
# ## Missing attributes can be added below manually (uncomment #), e.g.
# # ORBIT_DIRECTION = ascending
# PLATFORM                =    SENTINEL
# PROJECT_NAME            =    SANEM_T144f_askja
# ISCE_VERSION            =    2.4.2

export TTAG=`date +"%Y%m%dT%H%M%S"`
echo TTAG is ${TTAG}

echo "Starting smallbaselineApp.py now "
smallbaselineApp.py  ${CFG} --start ${STEP} | tee smallbaselineApp_${CFG}_${TTAG}.log

if [[ ! -f inputs/ifgramStack.h5 ]]; then
   echo error no output created
   exit -1
fi

echo "Dumping dates"
h5dump -d date inputs/ifgramStack.h5 | tee smallbaselineApp_${CFG}_${TTAG}.log

#******************** plot & save to pic ********************
view.py --dpi 150 --noverbose --nodisplay --update velocity.h5 --dem inputs/geometryRadar.h5 --mask maskTempCoh.h5 -u mm
view.py --dpi 150 --noverbose --nodisplay --update temporalCoherence.h5 -c gray -v 0 1
view.py --dpi 150 --noverbose --nodisplay --update maskTempCoh.h5 -c gray -v 0 1
view.py --dpi 150 --noverbose --nodisplay --update inputs/geometryRadar.h5
view.py --dpi 150 --noverbose --nodisplay --update avgPhaseVelocity.h5
view.py --dpi 150 --noverbose --nodisplay --update avgSpatialCoh.h5 -c gray -v 0 1
view.py --dpi 150 --noverbose --nodisplay --update maskConnComp.h5 -c gray -v 0 1
view.py --dpi 150 --noverbose --nodisplay --update timeseries.h5 --mask maskTempCoh.h5 --noaxis -u mm --wrap-range -10 10
if [[ -f timeseries_ERA5.h5 ]]; then
   view.py --dpi 150 --noverbose --nodisplay --update timeseries_ERA5.h5 --mask maskTempCoh.h5 --noaxis -u mm --wrap-range -10 10
fi
if [[ -f timeseries_ERA5_demErr.h5 ]]; then
   view.py --dpi 150 --noverbose --nodisplay --update timeseries_ERA5_demErr.h5 --mask maskTempCoh.h5 --noaxis -u mm --wrap-range -10 10
fi
view.py --dpi 150 --noverbose --nodisplay --update velocityERA5.h5 --mask no
view.py --dpi 150 --noverbose --nodisplay --update numInvIfgram.h5 --mask no

# ARIA products are already geocoded
if [[ -d geo ]]; then
   view.py --dpi 150 --noverbose --nodisplay --update geo/geo_maskTempCoh.h5 -c gray
   view.py --dpi 150 --noverbose --nodisplay --update geo/geo_temporalCoherence.h5 -c gray
   view.py --dpi 150 --noverbose --nodisplay --update geo/geo_velocity.h5 
   if [[ -f geo/geo_timeseries_ERA5_demErr.h5 ]];
      view.py --dpi 150 --noverbose --nodisplay --update geo/geo_timeseries_ERA5_demErr.h5 --mask maskTempCoh.h5 --noaxis -u mm --wrap-range -10 10
   fi
fi

#copy *.txt files into ./pic directory.
#move *.png/pdf/kmz files to ./pic directory.
#time used: 03 mins 3.7 secs.
# Explore more info & visualization options with the following scripts:
#         info.py                    #check HDF5 file structure and metadata
#         view.py                    #2D map view
#         tsview.py                  #1D point time-series (interactive)   
#         transect.py                #1D profile (interactive)
#         plot_coherence_matrix.py   #plot coherence matrix for one pixel (interactive)
#         plot_network.py            #plot network configuration of the dataset    
#         plot_transection.py        #plot 1D profile along a line of a 2D matrix (interactive)
#         save_kmz.py                #generate Google Earth KMZ file in raster image
#         save_kmz_timeseries.py     #generate Goodle Earth KMZ file in points for time-series (interactive)
        
# Go back to directory: /s22/insar/FORGE/S1/MINTPY_20210719

# ################################################
#    Normal end of smallbaselineApp processing!
# ################################################
# Time used: 03 mins 4.2 secs
