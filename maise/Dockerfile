# using this guide & mambaforge:
# https://github.com/yunjunz/conda_envs

FROM --platform=linux/amd64 docker.io/condaforge/mambaforge:latest as maise

# switch shell sh (default in Linux) to bash
# https://github.com/containers/podman/issues/8477
# https://stackoverflow.com/questions/55123637/activate-conda-environment-in-docker
# also make it a login shell so it adds .bashrc before each RUN command
SHELL ["/bin/bash", "--login", "-o", "pipefail", "-c"]

# create new environment & initialize it (adds conda environment stuff to .bashrc)
RUN mamba create --name maise --yes \
 && mamba init --system bash

# https://pythonspeed.com/articles/activate-conda-dockerfile/
# because "each RUN in a Dockerfile is a separate run of bash"

# install stuff that's available directory from conda-forge (isce2, mintpy)
RUN mamba install --name maise --channel conda-forge isce2 mintpy imagemagick --yes \
 && echo "conda activate maise" >> $HOME/.bashrc

# check that ISCE_HOME was set in the current environment by the above
RUN test -n "${ISCE_HOME-}"

# install ARIA-tools
RUN mkdir -p /tools \
 && cd /tools \
 && git clone https://github.com/aria-tools/ARIA-tools.git \
 && mamba install --name maise --channel conda-forge --file /tools/ARIA-tools/requirements.txt --yes \
 && cd /tools/ARIA-tools \
 && pip install -e .

# install SSARA
RUN git clone https://www.unavco.org/gitlab/unavco_public/ssara_client.git /tools/SSARA \
 && chmod +x /tools/SSARA/ssara_federated_query.py
ENV SSARA_HOME=/tools/SSARA

# install PyAPS
RUN pip install git+https://github.com/insarlab/PyAPS.git

# make everything under /tools/ writable
RUN chmod -R a+w /tools


# run some tests

# debug: check environment
#RUN env

RUN echo "export PATH=${ISCE_HOME}/bin:${ISCE_HOME}/applications:${PATH}" >> $HOME/.bashrc

RUN topsApp.py --help --steps
RUN ariaDownload.py --help
RUN smallbaselineApp.py --help
RUN /tools/SSARA/ssara_federated_query.py --help

# additional stack setup
# https://github.com/isce-framework/isce2/blob/main/contrib/stack/README.md
#ISCE_STACK={full_path_to_your_contrib/stack}
RUN echo "export PYTHONPATH=${PYTHONPATH}:${ISCE_STACK}" >> $HOME/.bashrc
RUN echo "export PATH=${PATH}:${ISCE_STACK}/topsStack" >> $HOME/.bashrc
RUN stackSentinel.py --help
