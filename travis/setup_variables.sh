#!/bin/bash -e
set -e

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
export MAVEN_OPTS="--add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.base/java.lang.reflect=ALL-UNNAMED --add-opens java.base/javax.crypto=ALL-UNNAMED --add-opens java.base/java.io=ALL-UNNAMED"
export TRAVIS_CPU_ARCH_JAVA="${TRAVIS_CPU_ARCH,,}"
if [ "$TRAVIS_CPU_ARCH" = "arm64" ]; then
    export TRAVIS_CPU_ARCH_STANDARD="aarch64"
    export TRAVIS_CPU_CORES="2"
else
    export TRAVIS_CPU_ARCH_STANDARD="${TRAVIS_CPU_ARCH,,}"
    export TRAVIS_CPU_CORES="2"
fi
export TRAVIS_OS_NAME_STANDARD="${TRAVIS_OS_NAME,,}"
if [ "$TRAVIS_OS_NAME_STANDARD" = "windows" ]; then
	export TRAVIS_OS_NAME_SHORT="win"
else
	export TRAVIS_OS_NAME_SHORT=$TRAVIS_OS_NAME_STANDARD
fi
if [ "$TRAVIS_OS_NAME_STANDARD" = "windows" ]; then
    export SRC_TDJNI_LIBNAME="libtdjni.dll"
    export DEST_TDJNI_LIBNAME="tdjni.dll"
else
    export SRC_TDJNI_LIBNAME="libtdjni.so"
    export DEST_TDJNI_LIBNAME="tdjni.so"
fi

# ====== OS Variables
if [[ "$TRAVIS_OS_NAME" == "windows" ]]; then
  export PATH="$PATH:/c/tools/php74:/c/PHP:/c/Program Files (x86)/Microsoft Visual Studio/2019/BuildTools/VC/Tools/MSVC/14.27.29110/bin/Hostx64/x64:/c/Program Files/OpenJDK/openjdk-11.0.8_10/bin:/c/Program Files/CMake/bin:/c/ProgramData/chocolatey/bin:/c/Program Files/apache-maven-3.6.3/bin:/c/ProgramData/chocolatey/lib/maven/apache-maven-3.6.3/bin:/c/ProgramData/chocolatey/lib/base64/tools:/c/Program Files/NASM"
  export JAVA_HOME="/c/Program Files/OpenJDK/openjdk-11.0.8_10"
  export VCPKG_DIR=$TRAVIS_BUILD_DIR/vcpkg
elif [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
  export PATH="$PATH:/usr/lib/jvm/java-11-openjdk-$TRAVIS_CPU_ARCH_JAVA/bin"
  export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-$TRAVIS_CPU_ARCH_JAVA"
  export JAVA_INCLUDE_PATH="/usr/lib/jvm/java-11-openjdk-$TRAVIS_CPU_ARCH_JAVA/include"
fi

# ====== Print variables
echo "TD_SRC_DIR=${TD_SRC_DIR}"
echo "TD_BIN_DIR=${TD_BIN_DIR}"
echo "TDNATIVES_BIN_DIR=${TDNATIVES_BIN_DIR}"
echo "TDNATIVES_CPP_SRC_DIR=${TDNATIVES_CPP_SRC_DIR}"
echo "TDNATIVES_DOCS_BIN_DIR=${TDNATIVES_DOCS_BIN_DIR}"
echo "TD_BUILD_DIR=${TD_BUILD_DIR}"
echo "TDNATIVES_CPP_BUILD_DIR=${TDNATIVES_CPP_BUILD_DIR}"
echo "JAVA_SRC_DIR=${JAVA_SRC_DIR}"
echo "TDLIB_SERIALIZER_DIR=${TDLIB_SERIALIZER_DIR}"
echo "PATH=${PATH}"
echo "JAVA_HOME=${JAVA_HOME}"
echo "JAVA_INCLUDE_PATH=${JAVA_INCLUDE_PATH}"
echo "VCPKG_DIR=${VCPKG_DIR}"
echo "MAVEN_OPTS=${MAVEN_OPTS}"
echo "TRAVIS_CPU_ARCH=${TRAVIS_CPU_ARCH}"
echo "TRAVIS_CPU_ARCH_JAVA=${TRAVIS_CPU_ARCH_JAVA}"
echo "TRAVIS_CPU_ARCH_STANDARD=${TRAVIS_CPU_ARCH_STANDARD}"
echo "TRAVIS_OS_NAME=${TRAVIS_OS_NAME}"
echo "TRAVIS_OS_NAME_STANDARD=${TRAVIS_OS_NAME_STANDARD}"
echo "TRAVIS_OS_NAME_SHORT=${TRAVIS_OS_NAME_SHORT}"
echo "SRC_TDJNI_LIBNAME=${SRC_TDJNI_LIBNAME}"
echo "DEST_TDJNI_LIBNAME=${DEST_TDJNI_LIBNAME}"
