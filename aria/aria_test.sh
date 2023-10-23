#!/bin/bash -vx

mamba activate ARIA-tools
ariaDownload.py -v --bbox '40.3480000000 40.4490000000 -119.4600000000 -119.3750000000' --output Download --start 20220331 --end 20220506 --track 42 -w ./products
ariaPlot.py -v -f "products/*.nc" -plotall  --figwidth=wide -nt 1
ariaTSsetup.py -f 'products/*.nc' --bbox '40.3480000000 40.4490000000 -119.4600000000 -119.3750000000' --mask Download --layers all -v -nt 1
