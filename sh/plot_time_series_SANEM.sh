#!/bin/bash -ex

source /opt/isce2/isce_env.sh
export PATH=$PATH:$HOME/MintPy/mintpy/
export PATH=$PATH:$HOME/PyAPS/

#timeseries2vel.py --help

# need this, too for PyAPS pyaps3
export PYTHONPATH=$PYTHONPATH:$HOME/MintPy/mintpy/:$HOME/PyAPS


# reference wrt GARL
reflalo="40.4165266 -119.3554565" # GARL 
sublat="40.348 40.449" # includes GARL
sublon="-119.46 -119.350" #includes GARL
figtitle=`echo $PWD | awk '{print $1"_wrtGARL"}'` # must be one word 

# consider referencing with respect to a well located in valley floor

# get file with wells
#\cp -v /Users/feigl/BoxSync/WHOLESCALE/Maps/SanEmidioWells/San_Emidio_Wells_2019WithLatLon.csv  .
#cat San_Emidio_Wells_2019WithLatLon.csv | awk -F, 'NR> 1{print $4,$17,$18}' | grep -v '"' > wells.namelalo
#cat /s12/insar/SANEM/Maps/SanEmidioWells2/San_Emidio_Wells_2019WithLatLon.csv | awk -F, 'NR> 1{print $4,$17,$18}' | grep -v '"' > wells.namelalo
cat ../San_Emidio_Wells_2019WithLatLon.csv | awk -F, 'NR> 1{print $4,$17,$18}' | grep -v '"' > wells.namelalo
#cp ../../wells.namelalo .

#
# for fbase in hgt incLocal lat lon los shadowMask
# do
#     #fname=${fbase}'.rdr'
#     fname=${fbase}'.rdr.full'
#     echo 'multilook ' ${fname}
#     if [ -f ${in_dir}/${fname}.vrt ]; then


#tsview.py --lalo 40.364713 -119.405194 --nodisplay --figext .pdf --unit mm --ylim -25 25 --figtitle Well45-21 geo_timeseries_ERA5_ramp_demErr.h5

## complete time series
#ftse='geo_timeseries_ERA5_ramp_demErr'
ftse=`ls -t geo_timeseries*.h5 | head -1 | sed 's/.h5//'`
echo ftse is $ftse

for wellname in `cat wells.namelalo | grep -e '25A-21' -e '65C-16' | awk '{print $1}'`; do
#for wellname in "25A-21"; do
#for wellname in "65C-16"; do
     echo wellname is $wellname
     # welllat=`cat wells.namelalo | grep ${wellname} | awk '{print $2}'`
     #echo welllat is ${welllat} 
     # welllon=`cat wells.namelalo | grep ${wellname} | awk '{print $3}' `
     # echo welllon is ${welllon} 
     
     welllalo=`cat wells.namelalo | grep ${wellname} | awk '{printf("%12.7f %12.7f",$2,$3)}' `
     echo welllalo is ${welllalo}

     pdfname1=`echo $wellname | awk '{print "Well"$1".pdf"}'`
     pdfname2=`echo $wellname | awk '{print "Well"$1"_ts.pdf"}'`
     pdfname3=`echo $wellname | awk '{print "Well"$1"_ts_tag.pdf"}'`
     echo pdfname1 is ${pdfname1} pdfname2 is ${pdfname2}

      # make time series plot
    # to clip add this switch --ylim -25 25
    tsview.py --outfile ${pdfname1} --lalo ${welllalo} --dpi 600 --ref-lalo ${reflalo} --ylim -50  10 \
    --show-gps --ref-gps GARL  \
    --nodisplay --figext .pdf --zf  --unit mm ${ftse}.h5


     txtname1=`echo $wellname | awk '{print "Well"$1"_ts.txt"}'`
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


