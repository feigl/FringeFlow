#!/bin/bash 
# set -v # verbose
# set -x # for debugging
# set -e # exit on error
# set -u # error on unset variables

bname=`basename $0`

Help()
{
   # Display Help
    echo "$bname will make time series plot of an .h5 file"
    echo "usage:   $bname timeseries.h5"
    exit -1
  }

############################################################
############################################################
# Main program                                             #
############################################################
############################################################
if [[  ( "$#" -ne 1)  ]]; then
    Help
fi

h5file=$1
ftse=$(echo $h5file | sed 's/.h5//' )
echo ftse is $ftse

# reference wrt GARL
reflalo="40.4165266 -119.3554565" # GARL 
sublat="40.348 40.449" # includes GARL
sublon="-119.46 -119.350" #includes GARL
# consider referencing with respect to a well located in valley floor

# get file with wells
#\cp -v /Users/feigl/BoxSync/WHOLESCALE/Maps/SanEmidioWells/San_Emidio_Wells_2019WithLatLon.csv  .
#cat San_Emidio_Wells_2019WithLatLon.csv | awk -F, 'NR> 1{print $4,$17,$18}' | grep -v '"' > wells.namelalo
#cat /s12/insar/SANEM/Maps/SanEmidioWells2/San_Emidio_Wells_2019WithLatLon.csv | awk -F, 'NR> 1{print $4,$17,$18}' | grep -v '"' > wells.namelalo
#cat ../San_Emidio_Wells_2019WithLatLon.csv | awk -F, 'NR> 1{print $4,$17,$18}' | grep -v '"' > wells.namelalo
#cp ../../wells.namelalo .
cat $SITE_DIR/sanem/well_specs_wUTMandLatLon.csv | awk -F, 'NR> 1{print $2,$9,$10}' | grep -v '"' > wells.namelalo

#tsview.py --lalo 40.364713 -119.405194 --nodisplay --figext .pdf --unit mm --ylim -25 25 --figtitle Well45-21 geo_timeseries_ERA5_ramp_demErr.h5

echo ftse is $ftse

for wellname in `cat wells.namelalo | grep -e '25A-21' -e '65C-16' | awk '{print $1}'`; do     
     welllalo=`cat wells.namelalo | grep ${wellname} | awk '{printf("%12.7f %12.7f",$2,$3)}' `
     echo welllalo is ${welllalo}

     pdfname1=`echo $ftse $wellname | awk '{print $1"_Well"$2".pdf"}'`
     pdfname2=`echo $ftse $wellname | awk '{print $1"_Well"$2"_ts.pdf"}'`
     pdfname3=`echo $ftse $wellname | awk '{print $1"_Well"$2"_ts_tag.pdf"}'`
     echo pdfname1 is ${pdfname1} 
     echo pdfname2 is ${pdfname2} 
     echo pdfname3 is ${pdfname3}

     figtitle=`echo $PWD $wellname | sed 's%/%_%g'| awk '{print $1"_"$2}'` # must be one word remove slashes
     echo figtitle is $figtitle

     # make time series plot
     # to clip add this switch --ylim -25 25
     # --show-gps --ref-gps GARL  \
     # --ref-lalo ${reflalo}
     tsview.py --outfile ${pdfname1} --lalo ${welllalo} --dpi 600  --ylim -50  10 --nodisplay --figext .pdf --zf  --unit mm ${ftse}.h5

     txtname1=`echo $ftse  $wellname | awk '{print $1"_Well"$2"_ts.txt"}'`
     echo txtname1 is ${txtname1}
     intercept=`grep intercept ${txtname1} | sed 's/#//'`
     echo intercept is ${intercept}
     velocity=`grep velocity ${txtname1} | sed 's/#//'`
     echo velocity is ${velocity}

     # tag it using ImageMagick
     #fileinfo=`convert ${pdfname2} -ping -format "%t" info:`
     #echo fileinfo is ${fileinfo}

     # convert -list font  
     # -gravity northeast -annotate +60+350 "$intercept" \
     # -gravity northeast -annotate +60+450 "$velocity" \
     convert -density 600 $pdfname2 \
          -fill black -undercolor white \
          -font Ubuntu-Mono -pointsize 9 \
          -gravity northwest -annotate +60+100 $figtitle $pdfname3
     done


