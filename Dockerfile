FROM ubuntu:24.04
LABEL maintainer="Jiadong Zhou"



ENV TINI_VERSION=v0.19.0

RUN apt-get update && \
    apt-get install -y curl && \
    curl -fsSL https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini -o /usr/bin/tini && \
    chmod +x /usr/bin/tini


ENV SLURM_VERSION=24.11.0 \
  MUNGE_UID=64031 \
  SLURM_UID=64030 \
  WORKER_UID=64032

RUN groupadd -g $MUNGE_UID munge \
  && useradd  -m -c "MUNGE Uid 'N' Gid Emporium" -d /var/lib/munge -u $MUNGE_UID -g munge  -s /sbin/nologin munge \
  && groupadd -g $SLURM_UID slurm \
  && useradd  -m -c "Slurm workload manager" -d /var/lib/slurm -u $SLURM_UID -g slurm  -s /bin/bash slurm \
  && groupadd -g $WORKER_UID worker \
  && useradd  -m -c "Workflow user" -d /home/worker -u $WORKER_UID -g worker  -s /bin/bash worker

WORKDIR /packages
ADD slurm-deb/ /packages

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository -y universe && \
    add-apt-repository -y multiverse && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl wget \
        sudo \
        tree \
        mariadb-server libmariadb-dev \
        munge libmunge-dev \
        openssh-server openssh-client \
        net-tools \
        unzip \
        python3 && \
    apt-get install -y ./*.deb && \
    rm -rf /var/lib/apt/lists/*
    


CMD ["/bin/bash"]
