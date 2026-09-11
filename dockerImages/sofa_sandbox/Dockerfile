FROM ubuntu:26.04

SHELL ["/bin/bash", "-c"]


RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y \
    apt-utils \
    software-properties-common

RUN apt-get install -y \
    git \
    gh \
    net-tools \
    wget \
    curl \
    zip \
    unzip

# Install build tools
RUN apt-get install -y \
    build-essential \
    ninja-build \
    gcc \
    g++

RUN rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://pixi.sh/install.sh | sh
RUN curl -fsSL https://claude.ai/install.sh | bash

COPY docker-entrypoint.sh /
RUN chmod a+x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

RUN touch /root/.bashrc
RUN echo 'export PATH="/root/.pixi/bin:/root/.local/bin:$PATH"' >> /root/.bashrc

RUN git config --global user.email "<>"
RUN git config --global user.name "Bakpaul-AI-bot"

CMD ["/bin/bash"]
