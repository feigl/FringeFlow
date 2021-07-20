#!/bin/bash

# Useful commands in ISCE


https://github.com/scottyhq/isce_notes/blob/master/CheatSheat.md

# get information about a raw Sentinel (SAFE) file
export FILE=S1B_IW_SLC__1SDV_20170204T160912_20170204T160940_004152_0072F4_9D51
gdalinfo /vsizip/${FILE}.zip/${FILE}.SAFE

# The prefix "/vsizip//" means reading the .zip file in place
gdalinfo /vsizip//s22/insar/FORGE/S1/SLC2021/S1B_IW_SLC__1SDV_20210121T012616_20210121T012643_025246_030188_E48

gdalinfo /vsizip//Volumes/feigl/insar/FORGE/SSARA/S1B_IW_SLC__1SDV_20180113T012557_20180113T012624_009146_0105E5_CA17.zip
gdalinfo /vsizip//Volumes/feigl/insar/FORGE/SSARA/S1B_IW_SLC__1SDV_20180125T012557_20180125T012623_009321_010B9C_05AE.zip

gdalinfo /vsizip/S1B_IW_SLC__1SDV_20180125T012557_20180125T012623_009321_010B9C_05AE.zip

# get all the info
gdalinfo /vsizip/S1B_IW_SLC__1SDV_20180125T012557_20180125T012623_009321_010B9C_05AE.zip/S1B_IW_SLC__1SDV_20180125T012557_20180125T012623_009321_010B9C_05AE.SAFE

# install GDAL on Mac
http://www.kyngchaos.com/software/frameworks/

