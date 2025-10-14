#! /bin/bash

git clone https://github.com/UrielCh/opencv4nodejs packages/opencv4nodejs
sudo apt update
sudo apt install libopencv-dev cmake -y
sudo apt-get install --reinstall build-essential

cd packages/opencv4nodejs
npm install
npm install
