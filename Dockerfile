FROM ubuntu:24.04

ENV TZ=Europe/Athens
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt update -yq && apt upgrade -yq
RUN apt install -y vim software-properties-common git sudo wget locales curl \
  build-essential
RUN sudo locale-gen "en_US.UTF-8"
RUN update-locale LC_ALL="en_US.UTF-8"
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1
RUN apt install -yq python3-pip

# Create the gasket user.
RUN useradd -ms /bin/bash gasket && \
    echo gasket:gasket | chpasswd && \
    cp /etc/sudoers /etc/sudoers.bak && \
    echo 'gasket ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers
USER gasket
ENV HOME=/home/gasket
WORKDIR ${HOME}

ADD --chown=gasket:gasket ./prv-node ${HOME}/node_src
ADD --chown=gasket:gasket ./prv-jsxray ${HOME}/gasket_src

WORKDIR ${HOME}/node_src
RUN ./configure --debug && make -j4
RUN cp out/Debug/node /usr/local/bin/node

WORKDIR ${HOME}
