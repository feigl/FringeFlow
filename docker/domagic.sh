#!/bin/bash 

# Set up keys for ISCE, GMTSAR, MINTPY, and SSARA
# 2021/07/05 Kurt Feigl

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

    stardir=${PWD}

    if [[ -f ${tgz} ]]; then
        tar -C ${HOME} -xzvf ${tgz}
        ## copy keys here

        # cp -v $HOME/.netrc . 
        if [[ -f $HOME/.netrc ]]; then
            echo "File named $HOME/.netrc exists"
            ls -la $HOME/.netrc
        else
            echo "ERROR: could not find named $HOME/.netrc"
            exit -1
        fi

        # .ssh 
        if [[ -d $HOME/.ssh ]]; then
            echo "Directory $HOME/.ssh exists"
            chmod -R 700 $HOME/.ssh
            ls -la $HOME/.ssh
        else
            echo "ERROR: could not find directory named $HOME/.ssh"
            exit -1
        fi

        if [[ -f $HOME/model.cfg ]]; then
            echo "File named $HOME/model.cfg exists. Copying it to /home/ops/PyAPS/pyaps3/model.cfg "
            cp -fv $HOME/model.cfg /home/ops/PyAPS/pyaps3/model.cfg
        else
            echo "ERROR: missing key file named model.cfg"
            exit -1
        fi

        if [[ -f $HOME/password_config.py ]]; then
            echo "File named $HOME/password_config.py exists."
            if [[ -f $(which ssara_federated_query.py ) ]]; then
                export SSARA_HOME=$( dirname  $(which ssara_federated_query.py ))
                cp -vf $HOME/password_config.py ${SSARA_HOME}/password_config.py 
                echo "Checking for file named password_config.py in ${SSARA_HOME}"
                if [[ -f ${SSARA_HOME}/password_config.py ]]; then
                    ls -l ${SSARA_HOME}/password_config.py
                else
                    echo "ERROR: could not find ile named password_config.py in ${SSARA_HOME}"
                    exit -1
                fi
            else 
                echo "ERROR: could not find directory for SSARA"
                exit -1
            fi
        else
            echo "ERROR: Could not find file named $HOME/password_config.py"
            exit -1
        fi
    else
        echo "ERROR: could not find file named magic.tgz"
        echo "To make one, consider the following command"
        echo "cd; tar -czvf magic.tgz .netrc model.cfg password_config.py .ssh"
        exit -1
    fi
    cd ${startdir}
    exit 0
fi
