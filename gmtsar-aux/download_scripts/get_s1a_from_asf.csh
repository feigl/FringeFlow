#!/bin/tcsh -f

if ($#argv != 1) then
  echo ""
  echo "Usage: get_s1a_from_asf.csh data.list"
  echo ""
  exit 1
endif


set data_list = $1

foreach filename (`cat $data_list`)
    echo "Starting Downloading $filename " `date`
   get_asf.py --user=kjellywang --pass=xxxx $filename
    echo "Finishing Downloading $filename " `date`
end

