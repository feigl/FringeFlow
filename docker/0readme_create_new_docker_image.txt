## HOW TO CREATE A NEW DOCKER CONTAINER
https://www.dataset.com/blog/create-docker-image/

## OUTSIDE THE CONTAINER

docker pull ghcr.io/insarlab/mintpy:latest
docker run -it -v "$PWD":"$PWD" -w "$PWD" ghcr.io/insarlab/mintpy:latest

# INSIDE THE CONTAINER
cd 
cd tools
git clone https://github.com/aria-tools/ARIA-tools.git
cd ARIA-tools

python -m pip install -e .


# https://github.com/asfadmin/Discovery-asf_search
python3 -m pip install asf_search

export PYTHONPATH=${PYTHONPATH}:${HOME}ARIA-tools/tools/ARIAtools
export PATH=${PATH}:${HOME}/ARIA-tools/tools/ARIAtools

# possible error messages
(base) mambauser@4665d499d3b6:~/tools/ARIA-tools$ ariaDownload.py -h
Traceback (most recent call last):
  File "/opt/conda/bin/ariaDownload.py", line 7, in <module>
    exec(compile(f.read(), __file__, 'exec'))
  File "/home/mambauser/tools/ARIA-tools/tools/bin/ariaDownload.py", line 16, in <module>
    import asf_search as asf

    OUTSIDE THE CONTAINER
    docker ps # get the containerID
    docker commit 4665d499d3b6 feigl/mintpy_aria-tools # use containerID


#### 
## start with existing 

  # outside container
  docker run -it -v "$PWD":"$PWD" -w "$PWD" docker.io/nbearson/isce_chtc:20220204

# INSIDE THE CONTAINER
  cd 
  cd tools
  git clone https://github.com/aria-tools/ARIA-tools.git
  cd ARIA-tools
  python -m pip install -e .
  python3 -m pip install asf_search
  export PYTHONPATH=${PYTHONPATH}:${HOME}ARIA-tools/tools/ARIAtools
  export PATH=${PATH}:${HOME}/ARIA-tools/tools/ARIAtools

  OUTSIDE THE CONTAINER
  docker ps # get the containerID
  docker commit 5694f5030167 feigl/isce_mintpy_aria