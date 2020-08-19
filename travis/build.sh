#!/bin/bash -e
set -e

# ====== Setup environment variables
source ./travis/setup_variables.sh

# ====== Build Td
# Prepare build
cd $TD_BUILD_DIR
if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
  cmake -DCMAKE_BUILD_TYPE=Release -DTD_ENABLE_JNI=ON -DCMAKE_INSTALL_PREFIX:PATH=${TD_BIN_DIR} ${TD_SRC_DIR}
elif [[ "$TRAVIS_OS_NAME" == "windows" ]]; then
  cmake -A x64 -DCMAKE_BUILD_TYPE=Release -DTD_ENABLE_JNI=ON -DCMAKE_INSTALL_PREFIX:PATH=${TD_BIN_DIR} -DCMAKE_TOOLCHAIN_FILE:FILEPATH=$VCPKG_DIR/scripts/buildsystems/vcpkg.cmake ${TD_SRC_DIR}
fi
cmake --build $TD_BUILD_DIR --target prepare_cross_compiling

# Split sources
cd $TD_SRC_DIR
php SplitSource.php

# Build
cd $TD_BUILD_DIR
if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
  cmake --build $TD_BUILD_DIR --target tdjson -- -j2
  cmake --build $TD_BUILD_DIR --target tdjson_static -- -j2
  cmake --build $TD_BUILD_DIR --target install --config Release -- -j2
elif [[ "$TRAVIS_OS_NAME" == "windows" ]]; then
  cmake --build $TD_BUILD_DIR --target tdjson
  cmake --build $TD_BUILD_DIR --target tdjson_static
  cmake --build $TD_BUILD_DIR --target install --config Release
fi

# After build
cd $TD_SRC_DIR
php SplitSource.php --undo

# ====== Build TdNatives
cd $TDNATIVES_CPP_BUILD_DIR
if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
  cmake -DCMAKE_BUILD_TYPE=Release -DTD_BIN_DIR=${TD_BIN_DIR} -DTDNATIVES_BIN_DIR=${TDNATIVES_BIN_DIR} -DTDNATIVES_DOCS_BIN_DIR=${TDNATIVES_DOCS_BIN_DIR} -DTd_DIR=${TD_BIN_DIR}/lib/cmake/Td -DJAVA_SRC_DIR=${JAVA_SRC_DIR} -DTDNATIVES_CPP_SRC_DIR:PATH=$TDNATIVES_CPP_SRC_DIR $TDNATIVES_CPP_SRC_DIR
  cmake --build $TDNATIVES_CPP_BUILD_DIR --target install -- -j2
elif [[ "$TRAVIS_OS_NAME" == "windows" ]]; then
  cmake -A x64 -DCMAKE_BUILD_TYPE=Release -DTD_BIN_DIR=${TD_BIN_DIR} -DTDNATIVES_BIN_DIR=${TDNATIVES_BIN_DIR} -DTDNATIVES_DOCS_BIN_DIR=${TDNATIVES_DOCS_BIN_DIR} -DTd_DIR=${TD_BIN_DIR}/lib/cmake/Td -DJAVA_SRC_DIR=${JAVA_SRC_DIR} -DTDNATIVES_CPP_SRC_DIR:PATH=$TDNATIVES_CPP_SRC_DIR -DCMAKE_TOOLCHAIN_FILE:FILEPATH=$VCPKG_DIR/scripts/buildsystems/vcpkg.cmake $TDNATIVES_CPP_SRC_DIR
  cmake --build $TDNATIVES_CPP_BUILD_DIR --target install --config Release
fi