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
export PATH="$PATH:/c/Program Files/OpenJDK/openjdk-11.0.8_10/bin:/c/ProgramData/chocolatey/lib/maven/apache-maven-3.6.3/bin:/c/ProgramData/chocolatey/lib/base64/tools:/c/ProgramData/chocolatey/lib/nasm/tools:/c/ProgramData/chocolatey/lib/nasm:/c/Program Files/NASM:/c/Program Files/NASM/bin"
export JAVA_HOME="/c/Program Files/OpenJDK/openjdk-11.0.8_10"

# ====== Cleanup
rm $JAVA_SRC_DIR/it/tdlight/tdnatives/TdApi.java || true
rm $JAVA_SRC_DIR/it/tdlight/tdnatives/new_TdApi.java || true

# ====== Environment setup
mkdir -p $TRAVIS_BUILD_DIR/out || true
mkdir $TD_BUILD_DIR || true
mkdir $TDNATIVES_CPP_BUILD_DIR || true
choco install visualstudio2019buildtools
tree "/c/"
choco install openjdk11 --version=11.0.8.10
choco install maven --version=3.6.3
choco install base64
choco install gperf
choco install strawberryperl
choco install nasm

# Install OpenSSL and ZLib
cd $TRAVIS_BUILD_DIR
# openssl
mkdir $TRAVIS_BUILD_DIR/openssl-root
git clone https://github.com/openssl/openssl.git -b OpenSSL_1_1_1-stable
cd openssl
perl Configure enable-static-engine enable-capieng no-ssl2 -utf-8 VC-WIN64A --prefix=$TRAVIS_BUILD_DIR/openssl-root --openssldir=$TRAVIS_BUILD_DIR/openssl-root no-shared
nmake
nmake install
cd ..

# zlib
cd $TRAVIS_BUILD_DIR
mkdir $TRAVIS_BUILD_DIR/zlib-root
git clone https://github.com/madler/zlib.git -b v1.2.11
cd zlib
cmake -DCMAKE_INSTALL_PREFIX:PATH=$TRAVIS_BUILD_DIR/zlib-root -DSKIP_BUILD_EXAMPLES=ON .
cmake --build . --target install
cd ..

ls $TRAVIS_BUILD_DIR/openssl-root
ls $TRAVIS_BUILD_DIR/zlib-root

# ====== Build Td
cd $TD_BUILD_DIR
cmake -A x64 -DCMAKE_BUILD_TYPE=Release -DTD_ENABLE_JNI=ON -DCMAKE_INSTALL_PREFIX:PATH=${TD_BIN_DIR} ${TD_SRC_DIR}
cmake --build $TD_BUILD_DIR --target install

# ====== Build TdNatives
cd $TDNATIVES_CPP_BUILD_DIR
cmake -A x64 -DCMAKE_BUILD_TYPE=Release -DTD_BIN_DIR=${TD_BIN_DIR} -DTDNATIVES_BIN_DIR=${TDNATIVES_BIN_DIR} -DTDNATIVES_DOCS_BIN_DIR=${TDNATIVES_DOCS_BIN_DIR} -DTd_DIR=${TD_BIN_DIR}/lib/cmake/Td -DJAVA_SRC_DIR=${JAVA_SRC_DIR} -DTDNATIVES_CPP_SRC_DIR:PATH=$TDNATIVES_CPP_SRC_DIR $TDNATIVES_CPP_SRC_DIR
cmake --build $TDNATIVES_CPP_BUILD_DIR --target install

# ====== Copy output
mv $TDNATIVES_BIN_DIR/libtdjni.dll $TRAVIS_BUILD_DIR/out/libtdjni.dll
