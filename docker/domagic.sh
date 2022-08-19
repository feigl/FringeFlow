#!/bin/bash -vx

# Set up keys for ISCE, GMTSAR, MINTPY, and SSARA
# 2021/07/05 Kurt Feigl
# 2021/12/01 Kurt, Nick, Sam modifying
# 2022/08/04 Kurt

# folder named magic should contain these files
# (base) brady:~ feigl$ find magic -ls
# 13928409127        0 drwxrwxr-x    7 feigl            staff                 224 Aug 16 20:05 magic
# 14116091020        8 -rw-------    1 feigl            staff                  33 Aug 16 20:05 magic/.topoapi
# 14102042285        8 -rw-r--r--    1 feigl            staff                  75 Jun  9 13:38 magic/.netrc
# 14102042287        8 -rw-r--r--    1 feigl            staff                1017 Feb 14  2021 magic/model.cfg
# 14102042286        8 -rwx------    1 feigl            staff                 162 Jun 10  2021 magic/password_config.py
# 14102042279        0 drwxr-xr-x    7 feigl            staff                 224 Jul 15  2021 magic/.ssh
# 14102042281        8 -rw-------    1 feigl            staff                2610 Jul 15  2021 magic/.ssh/id_rsa
# 14102042283        8 -rw-r--r--    1 feigl            staff                 415 Jul 15  2021 magic/.ssh/authorized_keys2
# 14102042280        8 -rw-r--r--    1 feigl            staff                2166 Jul 15  2021 magic/.ssh/authorized_keys
# 14102042284        8 -rw-r--r--    1 feigl            staff                 579 Jul 15  2021 magic/.ssh/id_rsa.pub
# 14102042282        8 -rw-r--r--    1 feigl            staff                2478 Jul 15  2021 magic/.ssh/known_hosts
# create a zipped tar file with
# cd; tar -czvf magic.tgz


if [[  ( "$#" -ne 1)  ]]; then
    bname=`basename $0`
    echo "$bname will set up authentification keys for ISCE, GMTSAR, MINTPY, and SSARA"
    echo "usage:   $bname magic.tgz"
    exit -1
else
    echo "Starting script named $0"
    echo PWD is ${PWD}
    echo HOME is ${HOME}

    # input tar file name
    tgz=${1}

    startdir=${PWD}

    if [[ -f ${tgz} ]]; then
        tar -C ${HOME} -xzvf ${tgz}
        ## copy keys here

        # cp -v $HOME/.netrc . 
        if [[ -f $HOME/magic/.netrc ]]; then
            echo "File named $HOME/.netrc exists"
            cp -vf $HOME/magic/.netrc $HOME/.netrc
        else
            echo "ERROR: could not find named $HOME/magic/.netrc"
            exit -1
        fi

        # FIXME: /home/ops/PyAPS/pyaps3/model.cfg is not writable    
        if [[ -f $HOME/magic/model.cfg ]]; then
            echo "File named $HOME/magic/model.cfg exists. Copying it to /home/ops/PyAPS/pyaps3/model.cfg "
            cp -fv $HOME/magic/model.cfg ${HOME}/PyAPS/pyaps3/model.cfg
        else
            echo "ERROR: missing key file named model.cfg"
            exit -1
        fi

       # copy authentification files for SSARA
       # For memory: after the first execution of password_config.py, we get a .pyc file that is compiled.
        if [[ -f $HOME/magic/password_config.py ]]; then
            echo "File named $HOME/magic/password_config.py exists."
            if [ -d $HOME/ssara_client ]; then
                #export SSARA_HOME=$HOME/ssara_ops
                cp -rvf $HOME/ssara_client $PWD
                cp -vf $HOME/magic/password_config.py ${PWD}/password_config.py
                export SSARA_HOME=$PWD/ssara_client
                echo "Checking for file named password_config.py in ${SSARA_HOME}"
                if [[ -f ${SSARA_HOME}/password_config.py ]]; then
                    ls -l ${SSARA_HOME}/password_config.py
                else
                    echo "ERROR: could not find file named password_config.py in ${SSARA_HOME}"
                    exit -1
                fi
            else
                echo "ERROR: clean SSARA directory does not exist as $HOME/ssara_client"
                exit -1
            fi
        else
            echo "ERROR: Could not find magic SSARA password file named $HOME/magic/password_config.py"
            exit -1
        fi

        # Copy authentification files for ARIA-tools
        # https://github.com/aria-tools/ARIA-tools/blob/dev/README.md
        # REQUIRED: Acquire API key to access/download DEMs
        # Follow instructions listed here to generate and access API key through OpenTopography: 
        # https://opentopography.org/blog/introducing-api-keys-access-opentopography-global-datasets.
        # Add this API key to your '~/.topoapi' file and set permissions as so
        # echo "myAPIkey" > ~/.topoapi
        # chmod 600 ~/.topoapi
        if [[ -f $HOME/magic/.topoapi ]]; then
            echo "File named $HOME/magic/.topoapi exists. Copying it to /home/ops/ "
            cp -fv $HOME/magic/.topoapi ${HOME}
        else
            echo "ERROR: missing key file named model.cfg"
            exit -1
        fi

    else
        echo "ERROR: could not find file named magic.tgz"
        echo "To make one, consider the following command"
        echo "cd; tar -czvf magic.tgz magic/.netrc magic/model.cfg magic/password_config.py"
        exit -1
    fi

    # # .ssh 
    # if [[ -d $HOME/.ssh ]]; then
    #     echo "Directory $HOME/.ssh exists"
    #     chmod -R 700 $HOME/.ssh
    #     ls -la $HOME/.ssh
    # else
    #     echo "ERROR: could not find directory named $HOME/.ssh"
    #     exit -1
    # fi

    cd ${startdir}
    exit 0
fi
