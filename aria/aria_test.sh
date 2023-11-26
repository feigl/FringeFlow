#!/bin/bash -vx

mkdir ARIA
cd ARIA
mamba activate ARIA-tools
#ariaDownload.py -v --bbox '40.3480000000 40.4490000000 -119.4600000000 -119.3750000000' --output Download --start 20220331 --end 20220506 --track 42 -w ./products
ariaDownload.py -v --bbox '40.3480000000 40.4490000000 -119.4600000000 -119.350' --output Download --start 20220331 --end 20220506 --track 42 -w ./products

ariaPlot.py -v -f "products/*.nc" -plotall  --figwidth=wide -nt 1
ariaTSsetup.py -f 'products/*.nc' --bbox '40.3480000000 40.4490000000 -119.4600000000 -119.350' --mask Download --layers all -v -nt 1
cd ..

mkdir MINTPY_pyaps
cd MINTPY_pyaps
mamba activate mintpy
rm -rf inputs *.h5 pic
rm rms_timeseriesResidual_ramp.txt 
rm coherenceSpatialAvg.txt ls
rm reference_date.txt 

cp /Users/feigl/FringeFlow/mintpy/aria_pyaps.cfg .
smallbaselineApp.py aria_pyaps.cfg




