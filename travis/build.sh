#!/bin/bash -e
set -e

# ====== Setup environment variables
source ./travis/setup_variables.sh

# ====== Build Td
# Prepare build
cd $TD_BUILD_DIR
if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
  cmake -DCMAKE_BUILD_TYPE=Release -DTD_ENABLE_JNI=ON -DCMAKE_INSTALL_PREFIX:PATH=${TD_BIN_DIR} -DTD_SKIP_BENCHMARK=ON -DTD_SKIP_TEST=ON -DTD_SKIP_TG_CLI=ON ${TD_SRC_DIR}
elif [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
  cmake -DCMAKE_BUILD_TYPE=Release -DTD_ENABLE_JNI=ON -DCMAKE_INSTALL_PREFIX:PATH=${TD_BIN_DIR} -DTD_SKIP_BENCHMARK=ON -DTD_SKIP_TEST=ON -DTD_SKIP_TG_CLI=ON ${TD_SRC_DIR}
elif [[ "$TRAVIS_OS_NAME" == "windows" ]]; then
  cmake -A x64 -DCMAKE_BUILD_TYPE=Release -DTD_ENABLE_JNI=ON -DCMAKE_INSTALL_PREFIX:PATH=${TD_BIN_DIR} -DTD_SKIP_BENCHMARK=ON -DTD_SKIP_TEST=ON -DTD_SKIP_TG_CLI=ON -DCMAKE_TOOLCHAIN_FILE:FILEPATH=$VCPKG_DIR/scripts/buildsystems/vcpkg.cmake ${TD_SRC_DIR}
fi

if [ "$TRAVIS_CPU_ARCH" = "arm64" ]; then
  while true; do free -h ; sleep 2; done &
fi

  # Split sources
#if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
#  cmake --build $TD_BUILD_DIR --target prepare_cross_compiling -- -j${TRAVIS_CPU_CORES}
#  cd $TD_SRC_DIR
#  php SplitSource.php
#fi

# Build
cd $TD_BUILD_DIR
if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
  cmake --build $TD_BUILD_DIR --target install --config Release -- -j${TRAVIS_CPU_CORES}
elif [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
  cmake --build $TD_BUILD_DIR --target install --config Release -- -j${TRAVIS_CPU_CORES}
elif [[ "$TRAVIS_OS_NAME" == "windows" ]]; then
  cmake --build $TD_BUILD_DIR --target install --config Release -- -m
fi

# Undo split-sources
#if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
#  cd $TD_SRC_DIR
#  php SplitSource.php --undo
#fi

# ====== Build TdNatives
cd $TDNATIVES_CPP_BUILD_DIR
if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
  cmake -DCMAKE_BUILD_TYPE=Release -DTD_BIN_DIR=${TD_BIN_DIR} -DTDNATIVES_BIN_DIR=${TDNATIVES_BIN_DIR} -DTDNATIVES_DOCS_BIN_DIR=${TDNATIVES_DOCS_BIN_DIR} -DTd_DIR=${TD_BIN_DIR}/lib/cmake/Td -DJAVA_SRC_DIR=${JAVA_SRC_DIR} -DTDNATIVES_CPP_SRC_DIR:PATH=$TDNATIVES_CPP_SRC_DIR $TDNATIVES_CPP_SRC_DIR
  cmake --build $TDNATIVES_CPP_BUILD_DIR --target install -- -j${TRAVIS_CPU_CORES}
elif [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
  cmake -DCMAKE_BUILD_TYPE=Release -DTD_BIN_DIR=${TD_BIN_DIR} -DTDNATIVES_BIN_DIR=${TDNATIVES_BIN_DIR} -DTDNATIVES_DOCS_BIN_DIR=${TDNATIVES_DOCS_BIN_DIR} -DTd_DIR=${TD_BIN_DIR}/lib/cmake/Td -DJAVA_SRC_DIR=${JAVA_SRC_DIR} -DTDNATIVES_CPP_SRC_DIR:PATH=$TDNATIVES_CPP_SRC_DIR $TDNATIVES_CPP_SRC_DIR
  cmake --build $TDNATIVES_CPP_BUILD_DIR --target install -- -j${TRAVIS_CPU_CORES}
elif [[ "$TRAVIS_OS_NAME" == "windows" ]]; then
  cmake -A x64 -DCMAKE_BUILD_TYPE=Release -DTD_BIN_DIR=${TD_BIN_DIR} -DTDNATIVES_BIN_DIR=${TDNATIVES_BIN_DIR} -DTDNATIVES_DOCS_BIN_DIR=${TDNATIVES_DOCS_BIN_DIR} -DTd_DIR=${TD_BIN_DIR}/lib/cmake/Td -DJAVA_SRC_DIR=${JAVA_SRC_DIR} -DTDNATIVES_CPP_SRC_DIR:PATH=$TDNATIVES_CPP_SRC_DIR -DCMAKE_TOOLCHAIN_FILE:FILEPATH=$VCPKG_DIR/scripts/buildsystems/vcpkg.cmake $TDNATIVES_CPP_SRC_DIR
  cmake --build $TDNATIVES_CPP_BUILD_DIR --target install --config Release -- -m
fi
