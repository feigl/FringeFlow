# FringeFlow
Workflow for generating interferometric fringe patterns from synthetic aperture radar data

cd $HOME
if [[ -d FringeFlow ]]; do
    cd FringeFlow
    git pull
else
   git clone https://github.com/feigl/FringeFlow.git
fi

# for GMTSAR
source $HOME/FringeFlow/docker/setup_inside_container_gmtsar.sh  
load_start_docker_container_gmtsar.sh

# for ISCE and MINTPY
source $HOME/FringeFlow/docker/setup_inside_container_isce.sh  
load_start_docker_container_isce.sh

