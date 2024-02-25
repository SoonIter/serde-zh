#! /usr/bin bash
TAG='0.4.37'
echo $TAG
URL="https://github.com/rust-lang/mdbook/releases/download/v${TAG}/mdbook-v${TAG}-x86_64-unknown-linux-gnu.tar.gz"
echo $URL
curl -L $URL | tar xvz
./mdbook build