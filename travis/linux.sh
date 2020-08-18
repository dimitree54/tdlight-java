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

# ====== Environment setup
mkdir $TD_BUILD_DIR || true
mkdir $TDNATIVES_CPP_BUILD_DIR || true

# Install java and fix java paths
if [ "$TRAVIS_CPU_ARCH" = "aarch64" ]; then
    export TRAVIS_CPU_ARCH_JAVA="arm64"
else
    export TRAVIS_CPU_ARCH_JAVA="${TRAVIS_CPU_ARCH,,}"
fi
export PATH="$PATH:/usr/lib/jvm/java-11-openjdk-$TRAVIS_CPU_ARCH_JAVA/bin"
export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-$TRAVIS_CPU_ARCH_JAVA"
export JAVA_INCLUDE_PATH="/usr/lib/jvm/java-11-openjdk-$TRAVIS_CPU_ARCH_JAVA/include"

echo "PATH=${PATH}"
echo "JAVA_HOME=${JAVA_HOME}"
echo "JAVA_INCLUDE_PATH=${JAVA_INCLUDE_PATH}"

# ====== Build Td
cd $TD_BUILD_DIR
cmake -DCMAKE_BUILD_TYPE=Release -DTD_ENABLE_JNI=ON -DCMAKE_INSTALL_PREFIX:PATH=${TD_BIN_DIR} ${TD_SRC_DIR}
cmake --build $TD_BUILD_DIR --target install -- -j3

# ====== Build TdNatives
cd $TDNATIVES_CPP_BUILD_DIR
cmake -DCMAKE_BUILD_TYPE=Release -DTD_BIN_DIR=${TD_BIN_DIR} -DTDNATIVES_BIN_DIR=${TDNATIVES_BIN_DIR} -DTDNATIVES_DOCS_BIN_DIR=${TDNATIVES_DOCS_BIN_DIR} -DTd_DIR=${TD_BIN_DIR}/lib/cmake/Td -DJAVA_SRC_DIR=${JAVA_SRC_DIR} -DTDNATIVES_CPP_SRC_DIR:PATH=$TDNATIVES_CPP_SRC_DIR $TDNATIVES_CPP_SRC_DIR
cmake --build $TDNATIVES_CPP_BUILD_DIR --target install -- -j3

mv $TDNATIVES_BIN_DIR/libtdjni.so $TRAVIS_BUILD_DIR/out
