#!/bin/bash 

# Set up keys for ISCE, GMTSAR, MINTPY, and SSARA
# 2021/07/05 Kurt Feigl
# 2021/12/01 Kurt, Nick, Sam modifying
# 2022/08/04 Kurt

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
            echo "File named $HOME/magic/.netrc exists"
            cp -vf $HOME/magic/.netrc $HOME/.netrc
        elif [[ -f $HOME/.netrc ]]; then
            echo "File named $HOME/.netrc exists"
        else
            echo "ERROR: could not find named .netrc"
            exit -1
        fi

        # Add your Open Topo API key to `~/.topoapi`.Refer to ARIAtools installation instructions.
        if [[ -f $HOME/magic/.topoapi ]]; then
            echo "File named $HOME/magic/.topoapi exists"
            cp -vf $HOME/magic/.topoapi $HOME/.topoapi
        elif [[ -f $HOME/.topoapi ]]; then
            echo "File named $HOME/.topoapi exists"
        else
            echo "ERROR: could not find named .topapi"
            exit -1
        fi


        # FIXME: /home/ops/PyAPS/pyaps3/model.cfg is not writable    
        if [[ -f $HOME/magic/model.cfg ]]; then
            echo "File named $HOME/magic/model.cfg exists. Copying it to the correct place "
            if [[ -f ${HOME}/PyAPS/pyaps3/model.cfg ]]; then
                cp -fv $HOME/magic/model.cfg ${HOME}/PyAPS/pyaps3/model.cfg
            elif [[ -f /opt/conda/lib/python3.8/site-packages/pyaps3/model.cfg ]]; then
                echo "File named $HOME/magic/model.cfg exists. Copying it to opt/conda/lib/python3.8/site-packages/pyaps3/model.cfg "
                cp -fv $HOME/magic/model.cfg /opt/conda/lib/python3.8/site-packages/pyaps3/model.cfg
            elif [[ -f /opt/conda/envs/maise/lib/python3.11/site-packages/pyaps3/model.cfg ]]; then
                # '/var/lib/condor/execute/slot1/dir_752360/magic/model.cfg' -> '/opt/conda/envs/maise/lib/python3.11/site-packages/pyaps3/model.cfg'
                # cp: cannot remove '/opt/conda/envs/maise/lib/python3.11/site-packages/pyaps3/model.cfg': Permission denied

                echo "File named $HOME/magic/model.cfg exists. Copying it to /opt/conda/envs/maise/lib/python3.11/site-packages/pyaps3/model.cfg"
                chmod a+w /opt/conda/envs/maise/lib/python3.11/site-packages/pyaps3/model.cfg
                cp -fv $HOME/magic/model.cfg /opt/conda/envs/maise/lib/python3.11/site-packages/pyaps3/model.cfg
            else
                echo "ERROR $0 cannot find target."
            fi
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
            elif [[ -d /tools/SSARA/ ]]; then
                cp -vf $HOME/magic/password_config.py /tools/SSARA/password_config.py
                export SSARA_HOME=/tools/SSARA
            else
                echo "ERROR: clean SSARA directory does not exist as $HOME/ssara_client"
                exit -1
            fi
        else
            echo "ERROR: Could not find magic SSARA password file named $HOME/magic/password_config.py"
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
