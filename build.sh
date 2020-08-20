#!/bin/bash -e

# ====== Variables
export TD_SRC_DIR=${PWD}/dependencies/tdlight
export TD_BIN_DIR=${PWD}/bin-td
export TDNATIVES_BIN_DIR=${PWD}/bin-tdlib
export TDNATIVES_CPP_SRC_DIR=${PWD}/src/tdlib-cpp
export TDNATIVES_DOCS_BIN_DIR=${PWD}/bin-docs
export TD_BUILD_DIR=${PWD}/build-td
export TDNATIVES_CPP_BUILD_DIR=${PWD}/build-tdlib
export JAVA_SRC_DIR=${PWD}/src/tdlib-java
export TDLIB_SERIALIZER_DIR=${PWD}/dependencies/tdlib-serializer

# ====== Print variables
echo "TD_SRC_DIR=${TD_SRC_DIR}"
echo "TD_BIN_DIR=${TD_BIN_DIR}"
echo "JAVA_SRC_DIR=${JAVA_SRC_DIR}"

# ====== Cleanup

# ====== Environment setup
[ -d $TD_BUILD_DIR ] || mkdir $TD_BUILD_DIR
[ -d $TDNATIVES_CPP_BUILD_DIR ] || mkdir $TDNATIVES_CPP_BUILD_DIR

# ====== Build Td
cd $TD_BUILD_DIR
cmake -DCMAKE_BUILD_TYPE=Release -DTD_ENABLE_JNI=ON -DCMAKE_INSTALL_PREFIX:PATH=${TD_BIN_DIR} ${TD_SRC_DIR}
cmake --build $TD_BUILD_DIR --target install -- -j4

# ====== Build TdNatives
cd $TDNATIVES_CPP_BUILD_DIR
cmake -DCMAKE_BUILD_TYPE=Release -DTD_BIN_DIR=${TD_BIN_DIR} -DTDNATIVES_BIN_DIR=${TDNATIVES_BIN_DIR} -DTDNATIVES_DOCS_BIN_DIR=${TDNATIVES_DOCS_BIN_DIR} -DTd_DIR=${TD_BIN_DIR}/lib/cmake/Td -DJAVA_SRC_DIR=${JAVA_SRC_DIR} -DTDNATIVES_CPP_SRC_DIR:PATH=$TDNATIVES_CPP_SRC_DIR $TDNATIVES_CPP_SRC_DIR
cmake --build $TDNATIVES_CPP_BUILD_DIR --target install -- -j4

# ====== Patch generated java code
echo "Compilation done. Patching TdApi.java"
python3 $TDLIB_SERIALIZER_DIR $JAVA_SRC_DIR/it/tdlight/tdlib/TdApi.java $JAVA_SRC_DIR/it/tdlight/tdlib/new_TdApi.java $TDLIB_SERIALIZER_DIR/headers.txt
rm $JAVA_SRC_DIR/it/tdlight/tdlib/TdApi.java
unexpand --tabs=2 $JAVA_SRC_DIR/it/tdlight/tdlib/new_TdApi.java > $JAVA_SRC_DIR/it/tdlight/tdlib/TdApi.java
rm $JAVA_SRC_DIR/it/tdlight/tdlib/new_TdApi.java

