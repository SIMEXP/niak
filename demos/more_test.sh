#!/usr/bin/env bash

# Add the certificate for the backports
sudo gpg --keyserver pgpkeys.mit.edu --recv-key  8B48AD6246925553      
sudo gpg -a --export 8B48AD6246925553 | sudo apt-key add -
