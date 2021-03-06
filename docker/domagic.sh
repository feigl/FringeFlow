#!/bin/bash 

# Set up keys for ISCE, GMTSAR, MINTPY, and SSARA
# 2021/07/05 Kurt Feigl
# 2021/12/01 Kurt, Nick, Sam modifying

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
            cp -fv $HOME/magic/model.cfg /home/ops/PyAPS/pyaps3/model.cfg
        else
            echo "ERROR: missing key file named model.cfg"
            exit -1
        fi

       # copy authentification files for SSARA
       # For memory: after the first execution of password_config.py, we get a .pyc file that is compiled.
        if [[ -f $HOME/magic/password_config.py ]]; then
            echo "File named $HOME/magic/password_config.py exists."
            if [ -d /home/ops/ssara_client ]; then
                #export SSARA_HOME=$HOME/ssara_ops
                cp -r /home/ops/ssara_client $SSARA_HOME
                cp -vf $HOME/magic/password_config.py ${SSARA_HOME}/password_config.py
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
