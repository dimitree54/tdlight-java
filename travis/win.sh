#!/bin/bash

# Build deps
choco install gperf 
choco install strawberryperl 
choco install jdk11 -params 'installdir=c:\\java11'

# openssl
mkdir $TRAVIS_BUILD_DIR/openssl-root
git clone https://github.com/openssl/openssl.git -b OpenSSL_1_1_1-stable
cd openssl
perl Configure enable-static-engine enable-capieng no-ssl2 -utf-8 VC-WIN64A --prefix=$TRAVIS_BUILD_DIR/openssl-root --openssldir=$TRAVIS_BUILD_DIR/openssl-root no-shared
nmake
nmake install
cd ..

# zlib
mkdir $TRAVIS_BUILD_DIR/zlib-root
git clone https://github.com/madler/zlib.git -b v1.2.11
cd zlib
cmake -DCMAKE_INSTALL_PREFIX:PATH=$TRAVIS_BUILD_DIR/zlib-root -DSKIP_BUILD_EXAMPLES=ON .
cmake --build . --target install
cd ..

ls $TRAVIS_BUILD_DIR/openssl-root
ls $TRAVIS_BUILD_DIR/zlib-root

# Dirs
cd src/main/jni

export TD_SRC_DIR=${PWD}/td
export TD_BIN_DIR=${PWD}/jtdlib/td
export JAVA_SRC_DIR=$(dirname `pwd`)/java
cd jtdlib
mkdir build
mkdir jnibuild
echo "TD_SRC_DIR=${TD_SRC_DIR}"
echo "TD_BIN_DIR=${TD_BIN_DIR}"
echo "JAVA_SRC_DIR=${JAVA_SRC_DIR}"
mkdir $TRAVIS_BUILD_DIR/out
cd jnibuild

# Setup env
export JAVA_HOME="c:\\java11"

# Build
cmake -DCMAKE_BUILD_TYPE=Release -DTD_ENABLE_JNI=ON  -DCMAKE_INSTALL_PREFIX:PATH=${TD_BIN_DIR} -DCMAKE_TOOLCHAIN_FILE=$TRAVIS_BUILD_DIR\vcpkg\scripts\buildsystems\vcpkg.cmake ${TD_SRC_DIR}
cmake --build . --target install -- -j4


cd ../../../../../
#mvn install -X

cd src/main/jni/jtdlib/build
cmake -DCMAKE_BUILD_TYPE=Release -DTd_DIR=${TD_BIN_DIR}/lib/cmake/Td -DJAVA_SRC_DIR=${JAVA_SRC_DIR} -DCMAKE_INSTALL_PREFIX:PATH=.. -DCMAKE_TOOLCHAIN_FILE=$TRAVIS_BUILD_DIR\vcpkg\scripts\buildsystems\vcpkg.cmake ..
cmake --build . --target install -- -j4

cd ..
rm -r td


# Copy artifacts
cp bin/libtdjni.dll $TRAVIS_BUILD_DIR/out
