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
export PATH="$PATH:/c/Program Files/OpenJDK/openjdk-11.0.8_10/bin:/c/ProgramData/chocolatey/lib/maven/apache-maven-3.6.3/bin:/c/ProgramData/chocolatey/lib/base64/tools"
export JAVA_HOME="/c/Program Files/OpenJDK/openjdk-11.0.8_10"

# ====== Cleanup
rm $JAVA_SRC_DIR/it/tdlight/tdnatives/TdApi.java || true
rm $JAVA_SRC_DIR/it/tdlight/tdnatives/new_TdApi.java || true

# ====== Environment setup
mkdir -p $TRAVIS_BUILD_DIR/out
mkdir $TRAVIS_BUILD_DIR/out
mkdir $TD_BUILD_DIR || true
mkdir $TDNATIVES_CPP_BUILD_DIR || true
choco install openjdk11 --version=11.0.8.10
choco install maven --version=3.6.3
choco install base64
choco install gperf 
choco install strawberryperl 

# Install OpenSSL and ZLib
cd $TRAVIS_BUILD_DIR
git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg
./bootstrap-vcpkg.sh
./vcpkg.exe install openssl:x64-windows zlib:x64-windows

# ====== Build Td
cd $TD_BUILD_DIR
cmake -A x64 -DCMAKE_BUILD_TYPE=Release -DTD_ENABLE_JNI=ON -DCMAKE_INSTALL_PREFIX:PATH=${TD_BIN_DIR} -DCMAKE_TOOLCHAIN_FILE:FILEPATH=$TRAVIS_BUILD_DIR\\vcpkg\\scripts\\buildsystems\\vcpkg.cmake ${TD_SRC_DIR}
cmake --build $TD_BUILD_DIR --target install

# ====== Build TdNatives
cd $TDNATIVES_CPP_BUILD_DIR
cmake -A x64 -DCMAKE_BUILD_TYPE=Release -DTD_BIN_DIR=${TD_BIN_DIR} -DTDNATIVES_BIN_DIR=${TDNATIVES_BIN_DIR} -DTDNATIVES_DOCS_BIN_DIR=${TDNATIVES_DOCS_BIN_DIR} -DTd_DIR=${TD_BIN_DIR}/lib/cmake/Td -DJAVA_SRC_DIR=${JAVA_SRC_DIR} -DTDNATIVES_CPP_SRC_DIR:PATH=$TDNATIVES_CPP_SRC_DIR -DCMAKE_TOOLCHAIN_FILE:FILEPATH=$TRAVIS_BUILD_DIR\\vcpkg\\scripts\\buildsystems\\vcpkg.cmake $TDNATIVES_CPP_SRC_DIR
cmake --build $TDNATIVES_CPP_BUILD_DIR --target install

# ====== Copy output
mv $TDNATIVES_BIN_DIR/libtdjni.dll $TRAVIS_BUILD_DIR/out/libtdjni.dll
