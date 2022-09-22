# using this guide & mambaforge:
# https://github.com/yunjunz/conda_envs/tree/main/isce2

FROM --platform=linux/amd64 docker.io/condaforge/mambaforge:latest

# easy reference for the software versions (tags or commit hashes) which we're pulling & building
ENV MINTPY_VERSION=v1.4.1
ENV ISCE_VERSION=v2.6.1
ENV PYKML_VERSION=v1.1.0
ENV PYAPS_VERSION=v0.3.1
ENV ARIA_VERSION=v1.1.4

# number of processors used to build
ARG NPROC=16

# downloads/checkouts
RUN mkdir -p /tools \
 && cd /tools \
 && git clone --branch $ARIA_VERSION https://github.com/aria-tools/ARIA-tools.git \
 && git clone --branch $MINTPY_VERSION https://github.com/insarlab/MintPy.git \
 && git clone https://github.com/yunjunz/conda_envs.git \
 && mkdir -p isce2; cd isce2 \
 && mkdir -p src build; cd src \
 && git clone --branch $ISCE_VERSION https://github.com/isce-framework/isce2.git

# create new environment
RUN mamba create --name maise --yes \
 && mamba init

RUN echo "source activate maise" > ~/.bashrc
ENV PATH /opt/conda/envs/maise/bin:$PATH

# install requirements for isce2, MintPy, & ARIA-tools
RUN cd /tools \
 && mamba install -c conda-forge git pip make --file conda_envs/isce2/requirements.txt --file MintPy/requirements.txt --file ARIA-tools/requirements.txt --yes

# build & install isce2
RUN cd /tools/isce2/build \
 && cmake /tools/isce2/src/isce2 \
        -DCMAKE_INSTALL_PREFIX=/tools/isce2/install${ISCE_VERSION} \
        -DPYTHON_MODULE_DIR="$(python3 -c 'import site; print(site.getsitepackages()[-1])')" \
        -DCMAKE_PREFIX_PATH=${CONDA_PREFIX} \
        -DCMAKE_BUILD_TYPE=Release \
 && make -j $NPROC \
 && make install

ENV PYTHONPATH=/tools/isce2/install${ISCE_VERSION}:$PYTHONPATH
ENV ISCE_HOME=/tools/isce2/src/isce2
ENV PATH=$ISCE_HOME/applications:$PATH

# build & install MintPy
RUN cd /tools/MintPy/ \
 && python setup.py install

# build & install ARIA-tools
RUN cd /tools/ARIA-tools/ \
 && python setup.py install

RUN git clone https://www.unavco.org/gitlab/unavco_public/ssara_client.git /tools/SSARA \
 && chmod +x /tools/SSARA/ssara_federated_query.py
ENV SSARA_HOME=/tools/SSARA

#RUN pip install git+https://github.com/yunjunz/pykml.git@$PYKML_VERSION

RUN pip install git+https://github.com/insarlab/PyAPS.git@$PYAPS_VERSION

# make everything under /tools/ writable
RUN chmod -R a+w /tools

# test!
#RUN topsApp.py --help # topsApp returns 1 on help :/
RUN topsApp.py --help --steps
RUN ariaDownload.py --help
RUN smallbaselineApp.py --help
RUN /tools/SSARA/ssara_federated_query.py --help
RUN /tools/isce2/src/isce2/contrib/stack/topsStack/stackSentinel.py --help