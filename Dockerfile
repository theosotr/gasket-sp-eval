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

# Install Node
ADD --chown=gasket:gasket ./prv-node ${HOME}/node_src

WORKDIR ${HOME}/node_src
RUN ./configure --debug && make -j8
RUN sudo cp out/Debug/node /usr/local/bin/node
# ADD --chown=root:root ./test/node /usr/local/bin/node

USER root
# Install npm
RUN curl -L https://www.npmjs.com/install.sh | sh

# Install deno
COPY ./installation_scripts {HOME}/installation_scripts/
RUN ./installation_scripts/deno.sh
RUN rm -rf ./installation_scripts

# Install Gasket
USER gasket
RUN sudo chown -R 1001:1001 "${HOME}/.npm" 
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
