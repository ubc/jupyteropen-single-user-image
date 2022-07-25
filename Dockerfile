# sudo docker kill $(sudo docker ps -q);  sudo docker rm $(sudo docker ps -a -q); sudo docker rmi $(sudo docker images -q)
# sudo docker build --squash --no-cache -t 032401129069.dkr.ecr.ca-central-1.amazonaws.com/jupyterhub:jupyterlab-open .

ARG BASE_CONTAINER=jupyter/datascience-notebook
FROM $BASE_CONTAINER

LABEL maintainer="Rahim Khoja <rahim.khoja@ubc.ca>"

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
    gfortran && \
    ldconfig && \
    apt-get autoclean && \
    apt-get clean && \
    apt-get autoremove

USER jovyan

# Install Conda Packages (Plotly, SageMath)
RUN mamba create --yes -n sage sage python=3.9 && \
    mamba install --yes "jupyterlab>=3" "ipywidgets>=7.6" && \
    mamba install --yes -c conda-forge -c plotly "jupyterlab-drawio" \
    "plotly" \
    "jupyterlab-spellchecker" \
    "jupyter-dash" \
    "xeus-cling" \
    "openjdk=11" \
    "maven" \
    "ipython-sql" \
    "jupyterlab-lsp" \
    "jupyter-lsp-python" \
    "jupyter_bokeh"

RUN R -e 'require(devtools); \
    install_version("ggiraphExtra", repos = "http://cran.us.r-project.org", quiet = TRUE); \
    install_version("lisp", version = "0.1", repos = "http://cran.us.r-project.org", quiet = TRUE); \
    install_version("translate", version = "0.1.2", repos = "http://cran.us.r-project.org", quiet = TRUE)'

RUN mamba install --yes -c conda-forge \
    'r-stargazer' \
    'r-quanteda' \
    'r-quanteda.textmodels' \
    'r-quanteda.textplots' \
    'r-quanteda.textstats' \
    'r-caret' \
    'r-ggiraph' \
    'r-ggextra' \
    'r-isocodes' \
    'r-urltools' \
    'r-ggthemes' \
    'r-modelsummary' \
    'r-nsyllable' \
    'r-proxyc' \
    'r-tidytext' && \
    mamba clean --all -f -y

RUN pip install nbgitpuller \
    jupyterlab-git \
    jupyterlab-system-monitor \
    lckr-jupyterlab-variableinspector \
    jupyterlab_templates \
    jupyterlab-code-formatter \
    nbdime \
    black \
    pandas_ta \
    ccxt \
    isort \
    jupyterlab_latex \
    jupyterlab-github \
    mitosheet3 && \
    pip install jupytext --upgrade


RUN npm cache clean --force && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/jovyan

RUN jupyter labextension install jupyterlab-plotly && \
    jupyter labextension install @jupyter-widgets/jupyterlab-manager plotlywidget && \
    jupyter labextension install @techrah/text-shortcuts && \
    jupyter labextension install jupyterlab-spreadsheet && \
    jupyter labextension install jupyterlab_templates && \
    jupyter serverextension enable --py jupyterlab_templates && \
    jupyter serverextension enable nbgitpuller --sys-prefix && \
    jupyter lab build

USER root

RUN npm install -g --unsafe-perm ijavascript && ijsinstall --hide-undefined --install=global

RUN npm install -g --unsafe-perm itypescript && its --ts-hide-undefined --install=global

# Install Java kernel
RUN wget -O /opt/ijava-kernel.zip https://github.com/SpencerPark/IJava/releases/download/v1.3.0/ijava-1.3.0.zip && \
    unzip /opt/ijava-kernel.zip -d /opt/ijava-kernel && \
    cd /opt/ijava-kernel && \
    python install.py --sys-prefix && \
    rm /opt/ijava-kernel.zip

ENV SAGE_ROOT=/opt/conda/envs/sage/

RUN /opt/conda/envs/sage/bin/sage -c "install_scripts('/usr/local/bin')" && \
    ln -s "/opt/conda/envs/sage/bin/sage" /usr/bin/sage && \
    ln -s /usr/bin/sage /usr/bin/sagemath

RUN jupyter kernelspec install $(/opt/conda/envs/sage/bin/sage -sh -c 'ls -d /opt/conda/envs/sage/share/jupyter/kernels/sagemath'); exit 0

RUN chown -R jovyan:users /home/jovyan && \
    chmod -R 0777 /home/jovyan && \
    rm -rf /home/jovyan/*

USER jovyan

ENV HOME=/home/jovyan

WORKDIR $HOME
