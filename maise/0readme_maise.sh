(base) root@d76a04682dac:/s12/insar/SANEM/ARIA/T42_maise2# more 0README.TXT 

# test case for Nick on askja.ssec.wisc.edu 
# in folder /s12/insar/SANEM/ARIA/T42_maise2
# 2023/08/17 Kurt Feigl and Nick Bearson

# derived from previous effort here:
#rsync -rav porotomo.geology.wisc.edu:/t31/insar/SANEM/ARIA/T42_long/MINTPY_both/"*.cfg" MINTPY

# start container
load_start_docker_container_maise.sh /s12/insar/SANEM/ARIA/T42_maise2


# inside container

# source code
tar -C $HOME -xzf FringeFlow.tgz

# siteinfo use /home/feigl/siteinfo.tgz  
tar -C $HOME -xzf siteinfo.tgz

# paths
source $HOME/FringeFlow/docker/setup_inside_container_maise.sh
domagic.sh magic.tgz

# run aria, then mintpy
run_aria_mintpy.sh -n SANEM -m S1 -1 20220331 -2 20220506 -t 42

  
# try downloading first
bbox=`get_site_dims.sh sanem 1 | sed 's/-R//' | awk -F/ '{print $3,$4,$2,$1}'`
ariaDownload.py --track 42 --bbox "${bbox}" -o count --verbose
ariaDownload.py --track 42 --bbox "${bbox}" -o download --verbose --start 20220301 --end 20220601


# makes two trees. Prune one. 
rm S1-GUNW-D-R-042-tops-20220523_20210516-140723-41932N_39963N-PP-3fa0-v2_0_4.nc

rm S1-GUNW-D-R-042-tops-20220511*
rm products/S1-GUNW-D-R-042-tops-20220511*
rm products/S1-GUNW-D-R-042-tops-20220604_20220523-140724-41931N_39962N-PP-29a7-v2_0_4.nc
 
ariaPlot.py -f 'products/*.nc' -plotall
ariaTSsetup.py -f 'products/*.nc' --bbox "${bbox}" -d Download --mask Download
(base) root@d76a04682dac:/s12/insar/SANEM/ARIA/T42_maise2# ls
0README.TXT     MINTPY                         azimuthAngle    connectedComponents  id_rsa          magic.tgz           productBoundingBox  ssara_client  unwrappedPhase
DEM             SANEM_S1_42_20220331_20220506  bPerpendicular  error.log            incidenceAngle  mask                products            stack         user_bbox.json
FringeFlow.tgz  aux.tgz                        coherence       figures              lookAngle       password_config.py  siteinfo.tgz        t1.tmp
(base) root@d76a04682dac:/s12/insar/SANEM/ARIA/T42_maise2# ls $PWD/0README.TXT 
/s12/insar/SANEM/ARIA/T42_maise2/0README.TXT
(base) root@d76a04682dac:/s12/insar/SANEM/ARIA/T42_maise2# more 0README.TXT 

# test case for Nick on askja.ssec.wisc.edu 
# in folder /s12/insar/SANEM/ARIA/T42_maise2
# 2023/08/17 Kurt Feigl and Nick Bearson

# derived from previous effort here:
#rsync -rav porotomo.geology.wisc.edu:/t31/insar/SANEM/ARIA/T42_long/MINTPY_both/"*.cfg" MINTPY

# start container
load_start_docker_container_maise.sh /s12/insar/SANEM/ARIA/T42_maise2


# inside container

# source code
tar -C $HOME -xzf FringeFlow.tgz

# siteinfo use /home/feigl/siteinfo.tgz  
tar -C $HOME -xzf siteinfo.tgz

# paths
source $HOME/FringeFlow/docker/setup_inside_container_maise.sh
domagic.sh magic.tgz

# run aria, then mintpy
run_aria_mintpy.sh -n SANEM -m S1 -1 20220331 -2 20220506 -t 42

  
# try downloading first
bbox=`get_site_dims.sh sanem 1 | sed 's/-R//' | awk -F/ '{print $3,$4,$2,$1}'`
ariaDownload.py --track 42 --bbox "${bbox}" -o count --verbose
ariaDownload.py --track 42 --bbox "${bbox}" -o download --verbose --start 20220301 --end 20220601


# makes two trees. Prune one. 
rm S1-GUNW-D-R-042-tops-20220523_20210516-140723-41932N_39963N-PP-3fa0-v2_0_4.nc

rm S1-GUNW-D-R-042-tops-20220511*
rm products/S1-GUNW-D-R-042-tops-20220511*
rm products/S1-GUNW-D-R-042-tops-20220604_20220523-140724-41931N_39962N-PP-29a7-v2_0_4.nc
 
ariaPlot.py -f 'products/*.nc' -plotall
ariaTSsetup.py -f 'products/*.nc' --bbox "${bbox}" -d Download --mask Download

# test case for Nick 