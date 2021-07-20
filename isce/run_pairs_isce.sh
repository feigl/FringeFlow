#!/bin/bash -vx

# calculate an interferometric pair
#2021/06/10 Kurt Feigl

if [ "$#" -ne 5 ]; then
    bname=`basename $0`
    echo "$bname will calculate an interferometric pair "
    echo "usage:   $bname SAT TRK SITE reference_YYYYMMDD secondary_YYYYMMDD"
    echo "example: $bname S1 T53 SANEM 20190110  20190122"

    exit -1
fi

#export YYYYMMDD1="2019-10-02"
#export YYYYMMDD2="2019-11-16"

echo "Starting script named $0"
echo "Arguments are $1 $2 $3 $4 $5"
echo PWD is ${PWD}
echo HOME is ${HOME} 

# export t0=20190110
# export t1=20190122
export sat=$1
export trk=$2
export sit=$3
export t0=$4
export t1=$5

echo sat is $sat
echo trk is $trk
echo sit is $sit
echo t0 is $t0
echo t1 is $t1

export timetag=`date +"%Y%m%dT%H%M%S"`
echo timetag is ${timetag}
export runname="${sat}_${trk}_${sit}_${t0}_${t1}"
echo runname is ${runname}


#uncompress SSH keys ssh.tgz
tar -C ${HOME} -xzvf ssh.tgz
rm -vf ssh.tgz

# uncompress files for shell scripts and add to search path
tar -C ${HOME} -xzvf FringeFlow.tgz


#change working directory to folder with same name as run
#cd S1_144_SANEM_20190110_20190122
cd ${runname}
pwd

# echo "Copying input SLC files from askja"
# mkdir -p SLC
# rsync -rav feigl@askja.ssec.wisc.edu:/s12/insar/${sit}/${sat}/SLC/"${sat}*_V_${t0}*.zip" SLC
# rsync -rav feigl@askja.ssec.wisc.edu:/s12/insar/${sit}/${sat}/SLC/"${sat}*_V_${t1}*.zip" SLC

echo "Downloading SLC files"
mkdir -p SLC
cd SLC
echo PWD is now ${PWD}
which run_ssara.sh
run_ssara.sh $sat $trk $sit $t0 $t1 download | tee -a ../slc.log
ls -ltr | tee -a ../slc.log
cd ..

echo "Copying input ORBIT files from askja"
mkdir -p ORBITS
cd ORBITS
get_orbits_from_askja.sh | tee -a ../orbits.log
cd ..

echo "Making a DEM"
mkdir -p DEM
cd DEM
# make the DEM
echo "dem.py -a stitch -b $(get_site_dims.sh $site i) -r -s 1 -c" | tee -a ../dem.log
cd ..

echo "Running ISCE"
mkdir -p ISCE
cd ISCE
run_isce.sh ${site} | tee -a ../isce.log
ls -ltr | tee -a ../isce.log
# delete intermediate files
rm -rf configs stack run_files interferograms coreg_secondarys secondarys geom_reference reference
# delete input files
rm -rf SLC ORBITS
# keep final output 
find  baselines -type f -ls | tee baselines.lst
find  merged    -type f -ls | tee merged.lst
cd ..

### MINTPY will fail with only one pair
    # cd MINTPY
    # run_mintpy.sh
    # plot_interferograms.sh
    # cd ..

    # cd MINTPY/geo
    # plot_maps.sh
    # plot_time_series.sh
    # cd ../..

# remove keys
    rm -vf model.cfg .netrc password_config.py


# make a tar file 
    cd ..
    tar -czvf ${runname}_${timetag}.tgz $runname/ISCE

### send tar file back to askja
    #rsync -rav ${runname}_${timetag}.tgz feigl@askja.ssec.wisc.edu:/s12/insar 

    #https://linux.die.net/man/1/rsync
    # If you need to specify a different remote-shell user, keep in mind that the user@ prefix in front of the host is specifying the rsync-user value (for a module that requires user-based authentication). This means that you must give the '-l user' option to ssh when specifying the remote-shell, as in this example that uses the short version of the --rsh option:
    #rsync -av -e "ssh -l ssh-user" rsync-user@host::module /dest
    rsync -av -e "ssh -l feigl" ${runname}_${timetag}.tgz feigl@askja.ssec.wisc.edu:/s12/insar

### move output file to staging area
    #https://chtc.cs.wisc.edu/file-avail-largedata.shtml
    mv -v ${runname}_${timetag}.tgz /staging/groups/geoscience/insar

### remove large input file to avoid transfering it back 
    rm -v ${runname}.tgz

#     pwd
#     2  ls
#     3  tar -xzvf FringeFlow.tgz 
#     4  tar -xzvf magic.tgz 
#     5  tar -xzvf ssh.tgz 
#     6  more FringeFlow/README.md 
#     7  source $HOME/FringeFlow/docker/setup_inside_container_isce.sh
#     8  ls
#     9  rm -rf FringeFlow magic 
#    10  tar -C $HOME -xzvf FringeFlow.tgz 
#    11  tar -C $HOME -xzvf magic.tgz 
#    12  tar -C $HOME -xzvf ssh.tgz 
#    13  source $HOME/FringeFlow/docker/setup_inside_container_isce.sh
#    14  domagic.sh
#    15  domagic.sh magic.tgz 
#    16  sudo cp -vf source $HOME/FringeFlow/docker/setup_inside_container_isce.sh
#    17  rm /home/ops/ssara_client/password_config.py
#    18  ls -l /home/ops/ssara_client/password_config.py
#    19  chmod a+w /home/ops/ssara_client/password_config.py
#    20  pwd
#    21  ls $HOME
#    22  cp -rp /home/ops/ssara_client/ $HOME
#    23  cp -v $HOME/magic/password_config.py /home/ops/ssara_client/
#    24  chmod -R +w /home/ops/ssara_client/password_config.py
#    25  chmod -R +w $HOME/ssara_client/password_config.py
#    26  more $HOME/FringeFlow/docker/setup_inside_container_isce.sh 
#    27  pwd
#    28  export PATH=$HOME/ssara_client:$PATH
#    29  export PYTHONPATH=$HOME/ssara_client:$PYTHONPATH
#    30  pwd
#    31  ls
#    32  mkdir SLC
#    33  cd SLC
#    34  run_ssara.sh 
#    35  run_ssara.sh S1 64 COSOC 20200101 20200130
#    36  run_ssara.sh S1 64 COSOC 20200101 20200130 download
#    37  pwd
#    38  cd ..
#    39  ls
#    40  mkdir ORBITS
#    41  cd ORBITS
#    42  get_orbits_from_askja.sh 
#    43  cd ..
#    44  ls
#    45  tar -xzvf ssh.tgz 
#    46  ls -la .ssh
#    47  cp .ssh/id_rsa /home/ops/.ssh/id_rsa
#    48  echo $HOME
#    49  mkdir /home/ops/.ssh
#    50  which get_orbits_from_askja.sh
#    51  tar -C $HOME -xzvf ssh.tgz 
#    52  get_orbits_from_askja.sh 
#    53  more `which get_orbits_from_askja.sh`
#    54  pwd
#    55  ls
#    56  cp -v /staging/groups/geoscience/FringeFlow.tgz .
#    57  cp -v /staging/groups/geoscience/insar/FringeFlow.tgz .
#    58  tar -C $HOME -xzvf FringeFlow.tgz 
#    59  more `which get_orbits_from_askja.sh`
#    60  pwd
#    61  cd ORBITS/
#    62  get_orbits_from_askja.sh 
#    63  pwd
#    64  cd ..
#    65  ls
#    66  mkdir DEM
#    67  ls
#    68  cd DEM
#    69  dem.py -a stitch -b $(get_site_dims.sh coso i) -r -s 1 -c
#    70  vi 0README.TXT
#    71  cd ..
#    72  ls
#    73  mkdir ISCE
#    74  cd ISCE
#    75  run_isce.sh 
#    76  run_isce.sh cosoc
#    77  bg
#    78  kill -9
#    79  kill -9 %1
#    80  history
