#!/bin/bash -ex
# Make time series plots from output of MINTPY
if [[  "$#" -ne 1  ]]; then
     bname=`basename $0`
     echo "$bname make time series from output of MINTPY"
     echo "usage:   $bname file.h5"
     echo "example: $bname geo_timeseries_ERA5_demErr.h5"
     exit -1
fi

# 2021/08/09 Kurt Feigl siteinfo is now outside of FringeFlow


source /opt/isce2/isce_env.sh
export PATH=$PATH:$HOME/MintPy/mintpy/
export PATH=$PATH:$HOME/PyAPS/

#timeseries2vel.py --help

# need this, too for PyAPS pyaps3
export PYTHONPATH=$PYTHONPATH:$HOME/MintPy/mintpy/:$HOME/PyAPS

# reflalo="40.4165266 -119.3554565" # GARL 
# sublat="40.348 40.449" # includes GARL
# sublon="-119.46 -119.350" #includes GARL
# figtitle=`echo $PWD | awk '{print $1"_wrtGARL"}'` # must be one word 

reflalo="38.38549343099232 -112.8127091435896" # GranitePeak
sublat="38.256 38.639" # includes GranitePeak
sublon="-113.170  -112.487" #includes GranitePeak
figtitle=`echo $PWD | awk '{print $1"_wrtGranitePeak"}'` # must be one word 


#tsview.py --lalo 40.364713 -119.405194 --nodisplay --figext .pdf --unit mm --ylim -25 25 --figtitle Well45-21 geo_timeseries_ERA5_ramp_demErr.h5

## complete time series
#ftse='geo_timeseries_ERA5_ramp_demErr'
#ftse=`ls -t geo_timeseries*.h5 | head -1 | sed 's/.h5//'`
echo ftse is $ftse

# TODO check for updates
#csvname="$HOME/FringeFlow/siteinfo/forge/FORGE_GPS_MonitoringCoordinatesOnly.csv"
csvname="$HOME/siteinfo/forge/FORGE_GPS_MonitoringCoordinatesOnly.csv"
echo csvname is $csvname

#for wellname in `cat wells.namelalo | awk '{print $1}'`; do
for wellname in "GDM-09_060519"; do
     echo wellname is $wellname
     # welllat=`cat wells.namelalo | grep ${wellname} | awk '{print $2}'`
     #echo welllat is ${welllat} 
     # welllon=`cat wells.namelalo | grep ${wellname} | awk '{print $3}' `
     # echo welllon is ${welllon} 
     
     #welllalo=`cat wells.namelalo | grep ${wellname} | awk '{printf("%12.7f %12.7f",$2,$3)}' `
     welllalo=`cat ${csvname} | grep ${wellname} | awk -F, '{printf("%12.7f %12.7f",$3,$4)}' `
     
     echo welllalo is ${welllalo}

     pdfname1=`echo $wellname | awk '{print "Site_"$1".pdf"}'`
     pdfname2=`echo $wellname | awk '{print "Site_"$1"_ts.pdf"}'`
     pdfname3=`echo $wellname | awk '{print "Site_"$1"_ts_tag.pdf"}'`
     echo pdfname1 is ${pdfname1} pdfname2 is ${pdfname2}

      # make time series plot
    # to clip add this switch --ylim -25 25
    tsview.py --outfile ${pdfname1} --lalo ${welllalo} --dpi 600 --ref-lalo ${reflalo} --ylim -15 15 \
    --nodisplay --figext .pdf --zf  --unit mm ${ftse}.h5

     # Try to add GPS station -- fails
     # --show-gps --ref-gps GARL  \
     # downloading site list from UNR Geod Lab: http://geodesy.unr.edu/NGLStationPages/DataHoldings.txt
     # File "/opt/conda/lib/python3.8/site-packages/mintpy-1.3.0-py3.8.egg/mintpy/utils/plot.py", line 1068, in plot_gps
     # raise ValueError('input reference GPS site "{}" not available!'.format(inps.ref_gps_site))
     # ValueError: input reference GPS site "GARL" not available!


     txtname1=`echo $wellname | awk '{print "Site_"$1"_ts.txt"}'`
     echo txtname1 is ${txtname1}
     slope=`grep slope ${txtname1}`
     echo slope is ${slope}
   
	# tag it using ImageMagick
	fileinfo=`convert ${pdfname2} -ping -format "%t" info:`
	echo fileinfo is ${fileinfo}
	convert -density 600 ${pdfname2} \
	 -fill black -undercolor white \
	 -font Helvetica -pointsize 9 \
	 -gravity northwest -annotate +60+100 "$fileinfo" \
	 -gravity northeast -annotate +60+250 "$figtitle" \
	 -gravity northeast -annotate +60+350 "$slope" \
	 "$pdfname3"

 
done


