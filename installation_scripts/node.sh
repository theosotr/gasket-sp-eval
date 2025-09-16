#! /bin/bash

cd ${HOME}/node_src
./configure --debug && make -j8
sudo cp out/Debug/node /usr/local/bin/node
sudo rm -rf {HOME}/node_src
