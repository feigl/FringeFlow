#!/usr/bin/bash

# plot output of MINTPY as geocoded maps in UTM projection
# FORGE
# 2021/06/09 Kurt Feigl

# docker run -it --rm -v "$PWD/..":"$PWD/.." -w $PWD nbearson/isce_mintpy

source /opt/isce2/isce_env.sh
export PATH=$PATH:$HOME/MintPy/mintpy/
export PATH=$PATH:$HOME/PyAPS/

#timeseries2vel.py --help

# need this, too for PyAPS pyaps3
export PYTHONPATH=$PYTHONPATH:$HOME/MintPy/mintpy/:$HOME/PyAPS

# big area of interest
# lon,lat,zero
# -113.1687280468227,38.25665158645261,0 
# -112.4872024763751,38.25328060536711,0 
# -112.5027451322613,38.63801624117328,0 
# -113.1698950023518,38.63976941496358,0 
# -113.1687280468227,38.25665158645261,0 

		# <description>Outcrop Location picked from Google Earth image on</description>
		# <LookAt>
		# 	<longitude>-112.8127091435896</longitude>
		# 	<latitude>38.38549343099232</latitude>
		# 	<altitude>0</altitude>
		# 	<heading>0.0484374361552097</heading>
		# 	<tilt>0</tilt>
		# 	<range>1351.630250403653</range>

#cd /s12/insar/SANEM/SENTINEL/T144f_askja3/MINTPY/geo

# On Feb 27, 2020, at 14:35, Corné Kreemer <cornelisk@unr.edu> wrote:

# As for the data download: GARL happens automatically (it is a PBO station).
# WGS84 plotting coordinates for GARL: 40.4165266  -119.3554565
# reflalo="40.4165266 -119.3554565" # GARL
# sublat="40.348 40.449" # includes GARL
# sublon="-119.46 -119.350" #includes GARL
reflalo="38.38549343099232 -112.8127091435896" # GranitePeak
# sublat="38.256 38.639" # includes GranitePeak
# sublon="-113.170  -112.487" #includes GranitePeak
sublat="38.35 38.60" # includes GranitePeak
sublon="-112.95  -112.80" #includes GranitePeak

#figtitle='SanEmidio_SENTINEL_T144f4_referredToGPSstationGARL' # must be one word 
figtitle=`echo $PWD | awk '{print $1"_wrtGranitePeak"}'` # must be one word 


# get coordinates of sites
foldername=`dirname $0`
csvname=`echo ${foldername} | awk '{print $1"/FORGE_GPS_MonitoringCoordinatesOnly.csv"}'`
cat ${csvname} | awk -F, 'NR>1{printf("%12.7f %12.7f\n",$3,$4)}' > sites.lalo
    
## average velocity
#fvel='geo_velocity_ERA5_ramp_demErr'
fvel=`ls -t geo_timeseries*.h5 | head -1 | sed 's/timeseries/velocity/' | sed 's/.h5//'`
echo fvel is $fvel
\cp -uv geo_velocity.h5 ${fvel}.h5
ls -l ${fvel}.h5

## complete time series
#ftse='geo_timeseries_ERA5_ramp_demErr'
ftse=`ls -t geo_timeseries*.h5 | head -1 | sed 's/.h5//'`
echo ftse is $ftse

#save_kmz.py   --mask geo_maskTempCoh.h5 ${fvel}.h5

# map of average velocity - study area only
view.py -o ${fvel}_sub.pdf --nodisplay --ref-lalo ${reflalo}  --lalo-max-num 4 --fontsize 10 --figext .pdf --lalo-label \
--unit mm/year --scalebar 0.3 0.2 0.05 --cbar-label LOS_displacement_[mm/year] --sub-lat ${sublat} --sub-lon ${sublon}  \
--pts-file sites.lalo --pts-marker '>w' --pts-ms 3 --figtitle ${figtitle} ${fvel}.h5  velocity


# map of average velocity over whole area
view.py -o ${fvel}.pdf --figtitle ${figtitle} --nodisplay --ref-lalo ${reflalo} --pts-file sites.lalo --pts-marker '>w' \
--lalo-max-num 4 --fontsize 10 --figext .pdf --lalo-label --unit mm/year --scalebar 0.3 0.2 0.05  \
--cbar-label LOS_displacement_[mm/year]  ${fvel}.h5 velocity

# map all pairs w.r.t. reference in study area
view.py -o ${ftse}_sub.pdf --nodisplay --ref-lalo ${reflalo} --unit mm --sub-lat ${sublat} --sub-lon ${sublon}  \
--pts-file sites.lalo --pts-marker '>w' --figext .pdf ${ftse}.h5

# map all pairs w.r.t. reference whole area
view.py -o ${ftse}.pdf --nodisplay --ref-lalo ${reflalo} --unit mm --figtitle ${figtitle} --figext .pdf \
--pts-file sites.lalo --pts-marker '>w' ${ftse}.h5


exit


# E-W transect through latitude of well 25A-21
#(base) bash-4.1$ grep 25A San_Emidio_Wells_2019WithLatLon.csv
#Point,295420,4471351,25A-21,295420,4471351,1241,605,Production,0,SE South,Elevation relative to KB,0,0,,,40.3676487,-119.4095383
#plot_transection.py geo_velocity.h5                    --coord geo  --start-lalo 40.3676487 -119.9 --end-lalo 40.3676487 -119.0  --figtitle ${figtitle} 
#plot_transection.py geo_timeseries_tropHgt_ramp_demErr.h5 --coord geo  --start-lalo 40.3676487 -119.9 --end-lalo 40.3676487 -119.0  --figtitle SanEmidio_SENTINEL_T144d2_geo_timeseries_tropHgt_ramp_demErr -o geo_timeseries_tropHgt_ramp_demErr.transection.pdf

plot_transection.py ${fvel}.h5   --coord geo  --start-lalo 40.3676487 -119.9 --end-lalo 40.3676487 -119.0  \
--figtitle ${figtitle}  -o ${fvel}_transection.pdf







save_kmz.py   --mask geo_maskTempCoh.h5 geo_velocity.h5 

# save as GMT grd file for known date. How to get list?
save_gmt.py geo_timeseries_ERA5_ramp_demErr.h5 20200105 -o geo_timeseries_ERA5_ramp_demErr.20200105.grd




# cbar label cannot contain any spaces

# get file with wells
#\cp -v /Users/feigl/BoxSync/WHOLESCALE/Maps/SanEmidioWells/San_Emidio_Wells_2019WithLatLon.csv  .
#/Volumes/GoogleDrive/Shared drives/WHOLESCALEshared/Maps/SanEmidioWells
cat San_Emidio_Wells_2019WithLatLon.csv | awk -F, 'NR> 1{print $17,$18}' | grep -v '"' > sites.lalo

# map of average velocity
view.py -o geo_velocity_sub.pdf --nodisplay --ref-lalo ${reflalo}  --lalo-max-num 4 --fontsize 10 --figext .pdf --lalo-label --unit mm/year --scalebar 0.3 0.2 0.05 --cbar-label LOS_displacement_[mm/year] --sub-lat ${sublat} --sub-lon ${sublon}  --pts-file sites.lalo --pts-marker '>w' --pts-ms 3 --figtitle ${figtitle} geo_velocity.h5 velocity

# all epochs whole area
view.py -o geo_timeseries_tropHgt_ramp_demErr.pdf --nodisplay --ref-lalo ${reflalo} --unit mm --figtitle ${figtitle} --figext .pdf --pts-file wells_production.lalo --pts-marker '>w' geo_timeseries_tropHgt_ramp_demErr.h5

# all epochs study area
view.py -o geo_timeseries_tropHgt_ramp_demErr_sub.pdf --nodisplay --ref-lalo ${reflalo} --unit mm --sub-lat ${sublat} --sub-lon ${sublon}  --pts-file sites.lalo --pts-marker '>w' --figext .pdf geo_timeseries_tropHgt_ramp_demErr.h5

# whole area
view.py -o geo_velocity.pdf --figtitle ${figtitle} --nodisplay --ref-lalo ${reflalo} --pts-file wells_production.lalo --pts-marker '>w' --lalo-max-num 4 --fontsize 10 --figext .pdf --lalo-label --unit mm/year --scalebar 0.3 0.2 0.05  --cbar-label LOS_displacement_[mm/year]  geo_velocity.h5 velocity

exit

save_kmz_timeseries.py --vel geo_velocity.h5 --tcoh geo_temporalCoherence.h5 --mask geo_maskTempCoh.h5 \
--steps 20 5 2 \
--lods 1000000 10000 100  \
geo_timeseries_tropHgt_ramp_demErr.h5



