# sudo docker kill $(sudo docker ps -q);  sudo docker rm $(sudo docker ps -a -q); sudo docker rmi $(sudo docker images -q)
# sudo docker build --squash --no-cache -t 032401129069.dkr.ecr.ca-central-1.amazonaws.com/jupyterhub:jupyterlab-open .

ARG BASE_CONTAINER=quay.io/jupyter/datascience-notebook:hub-5.2.0
#ARG BASE_CONTAINER=032401129069.dkr.ecr.ca-central-1.amazonaws.com/jupyterhub:jupyterlab-all
FROM $BASE_CONTAINER

LABEL maintainer="Bala Rao <bsriniva@ubc.ca>"
LABEL maintainer="Ryoko <ryoko.norden@ubc.ca>"

USER root

# Update System Packages for SageMath
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    dvipng \
    ffmpeg \
    imagemagick \
    texlive \
    tk tk-dev \
    jq \
    tzdata \
    curl \
    wget \
    unzip \
    zsh \
    vim \
    htop \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
# future version of base image will remove nodejs, uncomment below after upgrade
#    npm \
    gfortran && \
    ldconfig && \
    apt-get autoclean && \
    apt-get clean && \
    apt-get autoremove

USER ${NB_UID}

# Install Conda Packages (Plotly, SageMath)
RUN mamba create --yes -n sage sage=10.4 python=3.11 && \
    mamba install --yes -c conda-forge -c plotly \
    "plotly" \
    "jupyterlab-spellchecker" \
    "dash" \
    # installing xeus-cling will fail on arm64 platform
    "xeus-cling" \
    "openjdk" \
    "maven" \
    "ipython-sql" \
    "jupyterhub-singleuser" \
    "jupyterlab-lsp" \
    "jupyter-lsp-python" \
    "jupyter_bokeh"

RUN R -e 'require(devtools); \
    devtools::install_github("cardiomoon/ggiraphExtra"); \
    install.packages("https://cran.r-project.org/src/contrib/Archive/lisp/lisp_0.1.tar.gz", repos = NULL, type = "source", quiet = TRUE); \
    install.packages("https://cran.r-project.org/src/contrib/Archive/translate/translate_0.1.2.tar.gz", repos = NULL, type = "source", quiet = TRUE)'

# Install R packages
RUN mamba install --yes -c conda-forge \
    'r-stargazer' \
#    'r-quanteda' \
#    'r-quanteda.textmodels' \
#    'r-quanteda.textplots' \
#    'r-quanteda.textstats' \
    'r-caret' \
#    'r-ggiraph' \
    'r-ggextra' \
    'r-isocodes' \
    'r-urltools' \
    'r-ggthemes' \
    'r-modelsummary' \
    'r-nsyllable' \
#    'r-proxyc' \
#    'r-tidytext' \
    'r-car' && \
    mamba clean --all -f -y


RUN pip install --upgrade setuptools
RUN pip install nbgitpuller \
    pulp \
    jupyter-resource-usage \
    jupyterlab-code-formatter \
    black \
    pandas_ta \
    ccxt \
#    isort \
#    jupyterlab-github \
    jupyterlab-spreadsheet-editor \
    jupyterlab_templates \
    otter-grader \
    vl-convert-python \
    "vegafusion[embed]" \
    "vegafusion-jupyter[embed]"
RUN pip install jupytext --upgrade

# run jupyter lab build for jupyterlab-dash integration. prompted after logging in
RUN jupyter lab build && \
    jupyter lab clean && \
    npm cache clean --force && \
    rm -rf $HOME/.node-gyp && \
    rm -rf $HOME/.local && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/jovyan
RUN export NODE_OPTIONS=--max-old-space-size=4096

USER root

# Removed as the ijavascript has not been updated for more than 2 years
#RUN npm install -g --unsafe-perm ijavascript && ijsinstall --hide-undefined --install=global

#RUN npm install -g --unsafe-perm itypescript && its --ts-hide-undefined --install=global

# Install Java kernel
RUN wget -O /opt/ijava-kernel.zip https://github.com/SpencerPark/IJava/releases/download/v1.3.0/ijava-1.3.0.zip && \
    unzip /opt/ijava-kernel.zip -d /opt/ijava-kernel && \
    cd /opt/ijava-kernel && \
    python install.py --sys-prefix && \
    rm /opt/ijava-kernel.zip

ENV SAGE_ROOT=/opt/conda/envs/sage/

# install_scripts is deprecated
# RUN /opt/conda/envs/sage/bin/sage -c "install_scripts('/usr/local/bin')" && \
RUN ln -s "/opt/conda/envs/sage/bin/sage" /usr/bin/sage && \
    ln -s /usr/bin/sage /usr/bin/sagemath

RUN jupyter kernelspec install $(/opt/conda/envs/sage/bin/sage -sh -c 'ls -d /opt/conda/envs/sage/share/jupyter/kernels/sagemath'); exit 0

RUN curl -fsSL https://deno.land/install.sh | bash -s -- -y && /home/jovyan/.deno/bin/deno jupyter --unstable --install

COPY widget_selection.py /opt/conda/lib/python3.11/site-packages/ipywidgets/widgets/
COPY interaction.py /opt/conda/lib/python3.11/site-packages/ipywidgets/widgets/
RUN chown -R jovyan:users /home/jovyan && \
    chmod -R 0777 /home/jovyan && \
    rm -rf /home/jovyan/* && \
    # remove LC_ALL to workaround warning issue: https://github.com/r-lib/testthat/issues/1925
    echo "LC_ALL=en_US.UTF-8" >> /opt/conda/lib/R/etc/Renviron

USER jovyan

ENV HOME=/home/jovyan

WORKDIR $HOME
