#! /bin/bash

git clone --recurse-submodules https://github.com/Brooooooklyn/canvas.git packages/canvas
sudo apt update
sudo apt install libc++-dev libc++abi-dev clang cmake yasm -y
sudo wget -qO /usr/local/bin/ninja.gz https://github.com/ninja-build/ninja/releases/latest/download/ninja-linux.zip
sudo gunzip /usr/local/bin/ninja.gz
sudo chmod a+x /usr/local/bin/ninja
curl https://sh.rustup.rs -sSf | sh -s -- -y
source $HOME/.cargo/env
cd packages/canvas
node scripts/build-skia.js
node scripts/build-skia.js
sudo npm install -g yarn
yarn install --mode=skip-build
sed -i 's/^strip *= *"symbols"/strip = "none"/' Cargo.toml
yarn build
