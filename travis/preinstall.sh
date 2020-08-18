#!/bin/bash -e 
if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
    sudo apt-get -y install make git zlib1g-dev libssl-dev gperf php cmake openjdk-11-jdk-headless g++ ccache maven
fi
