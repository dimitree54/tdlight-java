#!/bin/bash -e

mkdir $TRAVIS_BUILD_DIR/out
cd src/main/jni

export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-$(dpkg --print-architecture)"
export PATH="$PATH:/usr/lib/jvm/java-11-openjdk-$(dpkg --print-architecture)/bin"

export TD_SRC_DIR=${PWD}/td
export TD_BIN_DIR=${PWD}/jtdlib/td
export JAVA_SRC_DIR=$(dirname `pwd`)/java
cd jtdlib
mkdir jnibuild || true
mkdir build || true
echo "TD_SRC_DIR=${TD_SRC_DIR}"
echo "TD_BIN_DIR=${TD_BIN_DIR}"
echo "JAVA_SRC_DIR=${JAVA_SRC_DIR}"
cd jnibuild
#export OPENSSL_ROOT_DIR=/snap/gitkraken/143/lib/x86_64-linux-gnu
#export JAVA_HOME=/usr/lib/jvm/java-1.13.0-openjdk-amd64
#export JAVA_INCLUDE_PATH=/usr/lib/jvm/java-1.13.0-openjdk-amd64/include/
cmake -DCMAKE_BUILD_TYPE=Release -DTD_ENABLE_JNI=ON -DCMAKE_INSTALL_PREFIX:PATH=${TD_BIN_DIR} ${TD_SRC_DIR}
cmake --build . --target install -- -j4

cd ../../../../../
#mvn install -X

cd src/main/jni/jtdlib/build
cmake -DCMAKE_BUILD_TYPE=Release -DTd_DIR=${TD_BIN_DIR}/lib/cmake/Td -DJAVA_SRC_DIR=${JAVA_SRC_DIR} -DCMAKE_INSTALL_PREFIX:PATH=.. ..
cmake --build . --target install -- -j4
cd ..
#rm -r jnibuild
#rm -r build
rm -r td
[ -e ../bin ] && rm -r ../bin
mkdir ../bin
mv docs ../bin
mv bin/libtdjni.so $TRAVIS_BUILD_DIR/out
