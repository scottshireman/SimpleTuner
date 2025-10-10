
# SimpleTuner needs CU141
#FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04
FROM nvidia/cuda:12.8.0-cudnn-devel-ubuntu22.04

# /workspace is the default volume for Runpod & other hosts
WORKDIR /workspace

# Update apt-get
RUN apt-get update -y

# Prevents different commands from being stuck by waiting
# on user input during build
ENV DEBIAN_FRONTEND noninteractive

# Install libg dependencies
RUN apt install libgl1-mesa-glx -y
RUN apt-get install 'ffmpeg'\
    'libsm6'\
    'libxext6'  -y

# Install misc unix libraries
RUN apt-get install -y --no-install-recommends openssh-server \
                                               openssh-client \
                                               git \
                                               git-lfs \
                                               wget \
                                               curl \
                                               tmux \
                                               tldr \
                                               nvtop \
                                               vim \
                                               rsync \
                                               net-tools \
                                               less \
                                               iputils-ping \
                                               7zip \
                                               zip \
                                               unzip \
                                               htop \
                                               inotify-tools

# Set up git to support LFS, and to store credentials; useful for Huggingface Hub
RUN git config --global credential.helper store && \
    git lfs install

# Install Python VENV
RUN apt-get install -y python3.10-venv

# Ensure SSH access. Not needed for Runpod but is required on Vast and other Docker hosts
EXPOSE 22/tcp
EXPOSE 8888/tcp

# Python
RUN apt-get update -y && apt-get install -y python3 python3-pip
RUN python3 -m pip install pip --upgrade

# HF
ENV HF_HOME=/workspace/huggingface

RUN pip3 install "huggingface_hub[cli]"

# WanDB
RUN pip3 install wandb

# Jupytrtr
RUN pip3 install ipyevents ipywidgets jupyter-archive jupyterlab

# Clone SimpleTuner
#RUN git clone https://github.com/bghira/SimpleTuner --branch release
RUN git clone https://github.com/scottshireman/SimpleTuner --branch release

# RUN git clone https://github.com/bghira/SimpleTuner --branch main # Uncomment to use latest (possibly unstable) version

#ENV VIRTUAL_ENV=/workspace/SimpleTuner/.venv
#ENV PATH="$VIRTUAL_ENV/bin:$PATH"

#RUN python3 -m venv ${VIRTUAL_ENV} && \
#    pip3 install --pre torch torchvision --index-url https://download.pytorch.org/whl/cu128 # && \
#    pip3 install poetry && \
#    cd SimpleTuner && \
#    poetry install --no-root

ENV VIRTUAL_ENV=/workspace/SimpleTuner/.venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN python3 -m venv "${VIRTUAL_ENV}" && \
    "${VIRTUAL_ENV}/bin/python" -m pip install --upgrade pip && \
    "${VIRTUAL_ENV}/bin/python" -m pip install \
        --index-url https://download.pytorch.org/whl/cu128 \
        "torch==2.7.1+cu128" "torchvision==0.22.1+cu128" && \
    "${VIRTUAL_ENV}/bin/python" -m pip install jupyterlab ipykernel poetry pyarrow && \
    cd SimpleTuner && \
    poetry config virtualenvs.create false && \
    poetry install --no-root && \
    "${VIRTUAL_ENV}/bin/python" -m ipykernel install \
        --name simpletuner \
        --display-name "Python (SimpleTuner venv)" \
        --sys-prefix


    

    #pip install -U xformers --index-url https://download.pytorch.org/whl/cu128 && \

# Install SimpleTuner
#RUN cd SimpleTuner && \
#    poetry install --no-root
    
RUN chmod +x SimpleTuner/train.sh

RUN echo "source ${VIRTUAL_ENV}/bin/activate" >> /root/.bashrc
# RUN echo "source /workspace/SimpleTuner/.venv/bin/activate" >> /root/.bashrc

WORKDIR /workspace/SimpleTuner
ADD docker-start.sh /
RUN chmod +x /docker-start.sh
CMD [ "/docker-start.sh" ]

# Copy start script with exec permissions
#COPY --chmod=755 /docker-start.sh /start.sh

# Dummy entrypoint
#ENTRYPOINT [ "/start.sh" ]
