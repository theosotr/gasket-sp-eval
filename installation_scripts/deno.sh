#! bin/bash

# Install Rust
curl https://sh.rustup.rs -sSf | sh -s -- -y

git clone https://github.com/grgalex/prv-deno deno
git clone https://github.com/grgalex/prv-rusty_v8 rusty_v8
cd rusty_v8
rm -rf v8
git clone https://github.com/grgalex/prv-v8-deno v8
git clone --branch 0.347.0 --single-branch https://github.com/denoland/deno_core
cd deno
V8_FROM_SOURCE=1 cargo --config .cargo/local-build.toml build
