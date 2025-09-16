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

RUN mkdir -p ${HOME}/installation_scripts
COPY ./installation_scripts/node.sh ${HOME}/installation_scripts/node.sh

# Install Node
ADD --chown=gasket:gasket ./prv-node ${HOME}/node_src
RUN ${HOME}/installation_scripts/node.sh


# Install npm
USER root
RUN curl -L https://www.npmjs.com/install.sh | sh

# Install deno
COPY ./installation_scripts/deno.sh ${HOME}/installation_scripts/deno.sh
RUN ./installation_scripts/deno.sh

RUN rm -rf ./installation_scripts

# Install Gasket
USER gasket
RUN sudo chown -R 1001:1001 "${HOME}/.npm" 
RUN sudo npm install -g node-gyp
RUN mkdir -p "$HOME/.npm-modules"
RUN npm config set prefix "$HOME/.npm-modules"
RUN echo 'export PATH="$HOME/.npm-modules/bin:$PATH"' >> ~/.bashrc
ADD --chown=gasket:gasket ./prv-jsxray ${HOME}/gasket_src
WORKDIR ${HOME}/gasket_src
RUN npm install && npm link

USER root
RUN apt install -y gdb

USER gasket

ENV GASKET_ROOT=${HOME}/gasket_src
WORKDIR ${HOME}
