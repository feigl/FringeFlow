#!/usr/bin/bash 

# plot output of MINTPY as geocoded maps 
# 2021/06/10 Kurt Feigl
# 2022/09/29 Kurt Feigl - adapt to MINTPY output from ARIA
# 2022/10/07 Kurt Feigl - adapt to time series, too
# 2023/09/30 Kurt Feigl - plot geo_velocity.h5

if [[ ( "$#" -ne 1 )  ]]; then
    bname=`basename $0`
    echo "$bname will make maps of site"
    echo "usage:   $bname site5"
    echo "example: $bname SANEM"
    echo "example: $bname FORGE"
    exit -1
fi

SITELC=`echo ${1} | awk '{ print tolower($1) }'`

# https://mintpy.readthedocs.io/en/latest/FAQs/
# For line-of-sight (LOS) phase in the unit of radians, i.e. ‘unwrapPhase’ dataset in ifgramStack.h5 file, 
# positive value represents motion away from the satellite. We assume the “date1_date2” format for the interferogram with “date1” being the earlier acquisition.

# For LOS displacement (velocity) in the unit of meters (m/yr), i.e. ‘timeseries’ dataset in timeseries.h5 file, 
# positive value represents motion toward the satellite (uplift for pure vertical motion).

reflalo="$(get_site_dims.sh ${SITELC} N) $(get_site_dims.sh ${SITELC} E)" # NE corner
sublat="$(get_site_dims.sh ${SITELC} S) $(get_site_dims.sh ${SITELC} N)"   
sublon="$(get_site_dims.sh ${SITELC} W) $(get_site_dims.sh ${SITELC} E)"
echo reflalo is $reflalo
echo sublat is $sublat
echo sublon is $sublon

# consider referencing with respect to a well located in valley floor


#save_kmz.py   --mask geo_maskTempCoh.h5 geo_velocity.h5 


# cbar label cannot contain any spaces

# get file with wells
cat $SITE_DIR/$SITELC/*wells.txt | awk '{print $2,$1}' > wells.lalo


for vfile in `ls *velocity.h5 *velocity*.h5` ; do
    echo vfile is $vfile
    ## average velocity
    if [[ -f $vfile ]]; then
        fvel=`echo $vfile | sed 's/.h5//'` 
        fmask='maskTempCoh'
    else
        echo ERROR cannot find $vfile
        exit -1
    fi
    echo fvel is $fvel
    ls -l ${fvel}.h5

    figtitle=`echo $PWD ${fvel} | awk '{print $1"/_"$2}'` # must be one word 
    echo figtitle is $figtitle

    # make KMZ file for Google Earth
    save_kmz.py  --mask ${fmask}.h5 ${fvel}.h5

    # map of average velocity over whole area
    view.py -o ${fvel}.pdf --figtitle ${figtitle} --nodisplay --save  \
    --lalo-max-num 4 --fontsize 10   --unit mm --ref-lalo ${reflalo} \
    --cbar-label 'LOS_velocity_[mm/year]' ${fvel}.h5 velocity

    # map of average velocity over study area
    view.py -o ${fvel}_sub.pdf --figtitle ${figtitle} --nodisplay --save  \
    --sub-lat $sublat --sub-lon $sublon --ref-lalo ${reflalo} \
    --lalo-max-num 4 --fontsize 10   --unit mm \
    --cbar-label 'LOS_velocity_[mm/year]' ${fvel}.h5 velocity

done


for tfile in `ls *timeseries*.h5` ; do
    echo tfile is $tfile
    if [[ -f $tfile ]]; then
        ftsr=`echo $tfile | sed 's/.h5//'` 
        fmask='maskTempCoh'
    else
        echo ERROR cannot find $tfile
        exit -1
    fi

    if [[ -f ${ftsr}.h5 ]]; then
        # map view, full area, all epochs
        view.py -o ${ftsr}.pdf     --save --nodisplay --cbar-label "LOS_displacement_[mm]_$PWD" \
        --unit mm  --lalo-max-num 4 ${ftsr}.h5

        # map view, sub area, all epochs
        view.py -o ${ftsr}_sub.pdf --save --nodisplay --cbar-label "LOS_displacement_[mm]_$PWD" \
        --unit mm  --lalo-max-num 4 --sub-lat $sublat --sub-lon $sublon ${ftsr}.h5
    else
        echo WARNING: cannot find HDF5 file named ${ftsr}.h5
    fi

done


if [[ -f geo_timeseries.h5 ]]; then
    view.py -o geo_timeseries.pdf     --save --nodisplay --cbar-label "LOS_displacement_[mm]_$PWD" --unit mm  --lalo-max-num 4 geo_timeseries.h5
    view.py -o geo_timeseries_sub.pdf --save --nodisplay --cbar-label "LOS_displacement_[mm]_$PWD" --unit mm  --lalo-max-num 4 --sub-lat $sublat --sub-lon $sublon timeseries.h5 geo_timeseries.h5
fi
if [[ -f geo_timeseries_ERA5_ramp_demErr.h5 ]]; then
    view.py -o geo_timeseries_ERA5_ramp_demErr.pdf     --save --nodisplay --cbar-label "LOS_displacement_[mm]_$PWD" --unit mm  --lalo-max-num 4 geo_timeseries_ERA5_ramp_demErr.h5
    view.py -o geo_timeseries_ERA5_ramp_demErr_sub.pdf --save --nodisplay --cbar-label "LOS_displacement_[mm]_$PWD" --unit mm  --lalo-max-num 4 --sub-lat $sublat --sub-lon $sublon geo_timeseries_ERA5_ramp_demErr.h5
fi


# save as GMT grd file for known date. How to get list?
save_gmt.py geo_timeseries_ERA5_ramp_demErr.h5 20200105 -o geo_timeseries_ERA5_ramp_demErr.20200105.grd

# cbar label cannot contain any spaces

# get file with wells
#\cp -v /Users/feigl/BoxSync/WHOLESCALE/Maps/SanEmidioWells/San_Emidio_Wells_2019WithLatLon.csv  .
#/Volumes/GoogleDrive/Shared drives/WHOLESCALEshared/Maps/SanEmidioWells
cat San_Emidio_Wells_2019WithLatLon.csv | awk -F, 'NR> 1{print $17,$18}' | grep -v '"' > wells.lalo

# map of average velocity
view.py -o geo_velocity_sub.pdf --nodisplay --ref-lalo ${reflalo}  --lalo-max-num 4 --fontsize 10 --figext .pdf --lalo-label --unit mm/year --scalebar 0.3 0.2 0.05 --cbar-label LOS_displacement_[mm/year] --sub-lat ${sublat} --sub-lon ${sublon}  --pts-file wells.lalo --pts-marker '>w' --pts-ms 3 --figtitle ${figtitle} geo_velocity.h5 velocity

# all epochs whole area
view.py -o geo_timeseries_tropHgt_ramp_demErr.pdf --nodisplay --ref-lalo ${reflalo} \
--unit mm --figtitle ${figtitle} --figext .pdf --pts-file wells_production.lalo \
--pts-marker '>w' geo_timeseries_tropHgt_ramp_demErr.h5

# all epochs study area
view.py -o geo_timeseries_tropHgt_ramp_demErr_sub.pdf --nodisplay --ref-lalo ${reflalo} --unit mm --sub-lat ${sublat} --sub-lon ${sublon}  --pts-file wells.lalo --pts-marker '>w' --figext .pdf geo_timeseries_tropHgt_ramp_demErr.h5

# whole area
view.py -o geo_velocity.pdf --figtitle ${figtitle} --nodisplay --ref-lalo ${reflalo} --pts-file wells_production.lalo --pts-marker '>w' --lalo-max-num 4 --fontsize 10 --figext .pdf --lalo-label --unit mm/year --scalebar 0.3 0.2 0.05  --cbar-label LOS_displacement_[mm/year]  geo_velocity.h5 velocity



# E-W transect through latitude of well 25A-21
#(base) bash-4.1$ grep 25A San_Emidio_Wells_2019WithLatLon.csv
#Point,295420,4471351,25A-21,295420,4471351,1241,605,Production,0,SE South,Elevation relative to KB,0,0,,,40.3676487,-119.4095383
#plot_transection.py geo_velocity.h5                    --coord geo  --start-lalo 40.3676487 -119.9 --end-lalo 40.3676487 -119.0  --figtitle ${figtitle} 
#plot_transection.py geo_timeseries_tropHgt_ramp_demErr.h5 --coord geo  --start-lalo 40.3676487 -119.9 --end-lalo 40.3676487 -119.0  --figtitle SanEmidio_SENTINEL_T144d2_geo_timeseries_tropHgt_ramp_demErr -o geo_timeseries_tropHgt_ramp_demErr.transection.pdf

plot_transection.py ${fvel}.h5 --coord geo  --start-lalo 40.3676487 -119.9 --end-lalo 40.3676487 -119.0  \
--figtitle ${figtitle}  -o ${fvel}_transection.pdf

save_kmz_timeseries.py --vel geo_velocity.h5 --tcoh geo_temporalCoherence.h5 --mask geo_maskTempCoh.h5 \
--steps 20 5 2 \
--lods 1000000 10000 100  \
geo_timeseries_tropHgt_ramp_demErr.h5



