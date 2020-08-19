#!/bin/bash -e

# ====== Variables
export TD_SRC_DIR=${PWD}/dependencies/tdlight
export TD_BIN_DIR=${PWD}/bin-td
export TDNATIVES_BIN_DIR=${PWD}/bin-tdnatives
export TDNATIVES_CPP_SRC_DIR=${PWD}/src/tdnatives-cpp
export TDNATIVES_DOCS_BIN_DIR=${PWD}/bin-docs
export TD_BUILD_DIR=${PWD}/build-td
export TDNATIVES_CPP_BUILD_DIR=${PWD}/build-tdnatives
export JAVA_SRC_DIR=${PWD}/src/tdnatives-java
export TDLIB_SERIALIZER_DIR=${PWD}/dependencies/tdlib-serializer

# ====== Print variables
echo "TD_SRC_DIR=${TD_SRC_DIR}"
echo "TD_BIN_DIR=${TD_BIN_DIR}"
echo "JAVA_SRC_DIR=${JAVA_SRC_DIR}"

# ====== OS Variables
export PATH="$PATH:/c/Program Files (x86)/Microsoft Visual Studio/2019/BuildTools/VC/Tools/MSVC/14.27.29110/bin/Hostx64/x64:/c/Program Files/OpenJDK/openjdk-11.0.8_10/bin:/c/Program Files/CMake/bin:/c/ProgramData/chocolatey/bin:/c/Program Files/apache-maven-3.6.3/bin:/c/ProgramData/chocolatey/lib/maven/apache-maven-3.6.3/bin:/c/ProgramData/chocolatey/lib/base64/tools:/c/Program Files/NASM"
export JAVA_HOME="/c/Program Files/OpenJDK/openjdk-11.0.8_10"
export VCPKG_DIR=$TRAVIS_BUILD_DIR/vcpkg

# ====== Cleanup
[ -f $JAVA_SRC_DIR/it/tdlight/tdnatives/TdApi.java ] && rm $JAVA_SRC_DIR/it/tdlight/tdnatives/TdApi.java
[ -f $JAVA_SRC_DIR/it/tdlight/tdnatives/new_TdApi.java ] && rm $JAVA_SRC_DIR/it/tdlight/tdnatives/new_TdApi.java

# ====== Environment setup
[ -d $TRAVIS_BUILD_DIR/out ] || mkdir -p $TRAVIS_BUILD_DIR/out
[ -d $TD_BUILD_DIR ] || mkdir $TD_BUILD_DIR
[ -d $TDNATIVES_CPP_BUILD_DIR ] || mkdir $TDNATIVES_CPP_BUILD_DIR
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

# ====== Build Td
cd $TD_BUILD_DIR
cmake -A x64 -DCMAKE_BUILD_TYPE=Release -DTD_ENABLE_JNI=ON -DCMAKE_INSTALL_PREFIX:PATH=${TD_BIN_DIR} -DCMAKE_TOOLCHAIN_FILE:FILEPATH=$VCPKG_DIR/scripts/buildsystems/vcpkg.cmake ${TD_SRC_DIR}
cmake --build $TD_BUILD_DIR --target install --config Release

# ====== Build TdNatives
cd $TDNATIVES_CPP_BUILD_DIR
cmake -A x64 -DCMAKE_BUILD_TYPE=Release -DTD_BIN_DIR=${TD_BIN_DIR} -DTDNATIVES_BIN_DIR=${TDNATIVES_BIN_DIR} -DTDNATIVES_DOCS_BIN_DIR=${TDNATIVES_DOCS_BIN_DIR} -DTd_DIR=${TD_BIN_DIR}/lib/cmake/Td -DJAVA_SRC_DIR=${JAVA_SRC_DIR} -DTDNATIVES_CPP_SRC_DIR:PATH=$TDNATIVES_CPP_SRC_DIR -DCMAKE_TOOLCHAIN_FILE:FILEPATH=$VCPKG_DIR/scripts/buildsystems/vcpkg.cmake $TDNATIVES_CPP_SRC_DIR
cmake --build $TDNATIVES_CPP_BUILD_DIR --target install --config Release

# ====== Copy output
mv $TDNATIVES_BIN_DIR/tdjni.dll $TRAVIS_BUILD_DIR/out/libtdjni.dll
