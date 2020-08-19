#!/bin/bash -e
set -e

# ====== Setup environment variables
./travis/setup_variables.sh

# ====== Environment cleanup
[ -f $JAVA_SRC_DIR/it/tdlight/tdnatives/TdApi.java ] && rm $JAVA_SRC_DIR/it/tdlight/tdnatives/TdApi.java
[ -f $JAVA_SRC_DIR/it/tdlight/tdnatives/new_TdApi.java ] && rm $JAVA_SRC_DIR/it/tdlight/tdnatives/new_TdApi.java

# ====== Environment setup
[ -d $TRAVIS_BUILD_DIR/out ] || mkdir -p $TRAVIS_BUILD_DIR/out
[ -d $TD_BUILD_DIR ] || mkdir $TD_BUILD_DIR
[ -d $TDNATIVES_CPP_BUILD_DIR ] || mkdir $TDNATIVES_CPP_BUILD_DIR

if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
  echo "Linux"
elif [[ "$TRAVIS_OS_NAME" == "windows" ]]; then
  echo "Windows"
  choco install ccache
  choco install visualstudio2019buildtools --version=16.7.0.0 --package-parameters "--add Microsoft.VisualStudio.Component.VC.Tools.x86.x64"
  choco install openjdk11 --version=11.0.8.10
  choco install maven --version=3.6.3
  choco install base64
  choco install gperf
  choco install strawberryperl
  choco install nasm

  git clone --depth=1 -b windows-amd64-prebuilt-libraries --single-branch https://github.com/tdlight-team/tdlight-java windowsenv
  mv windowsenv/vcpkg $VCPKG_DIR
else
  echo "Unrecognized os: $TRAVIS_OS_NAME"
  exit 1
fi
