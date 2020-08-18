#!/bin/bash -e

mkdir $TRAVIS_BUILD_DIR/out

# Build deps
choco install openjdk11
choco install maven

la -alch /c/ProgramData/chocolatey/lib
la -alch /c/ProgramData/chocolatey/lib/maven
la -alch /c/ProgramData/chocolatey/lib/maven/apache-maven-3.6.3-bin
la -alch /c/ProgramData/chocolatey/lib/maven/apache-maven-3.6.3-bin/bin
la -alch /c/ProgramData/chocolatey/lib/maven/apache-maven-3.6.3-bin/bin/mvn.cmd

choco install base64

touch "$TRAVIS_BUILD_DIR/out/libtdjni.dll"
exit 0

# Build deps
choco install gperf 
choco install strawberryperl 

# Setup variables
export PATH=$PATH:/c/ProgramData/chocolatey/lib/maven/bin:/c/ProgramData/chocolatey/lib/base64/tools
# End setup variables

cd $TRAVIS_BUILD_DIR
git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg
./bootstrap-vcpkg.bat
./vcpkg.exe install openssl:x64-windows zlib:x64-windows
cd ..

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
cd jnibuild

# Setup env
export JAVA_HOME="C:\\Program Files\\OpenJDK\\openjdk-11.0.8_10"

# Build
cmake -A x64 -DCMAKE_BUILD_TYPE=Release -DTD_ENABLE_JNI=ON  -DCMAKE_INSTALL_PREFIX:PATH=${TD_BIN_DIR} -DCMAKE_TOOLCHAIN_FILE:FILEPATH=$TRAVIS_BUILD_DIR\\vcpkg\\scripts\\buildsystems\\vcpkg.cmake ${TD_SRC_DIR}
cmake --build . --target install


cd ../../../../../
#mvn install -X

cd src/main/jni/jtdlib/build
cmake -A x64 -DCMAKE_BUILD_TYPE=Release -DTd_DIR=${TD_BIN_DIR}/lib/cmake/Td -DJAVA_SRC_DIR=${JAVA_SRC_DIR} -DCMAKE_INSTALL_PREFIX:PATH=.. -DCMAKE_TOOLCHAIN_FILE:FILEPATH=$TRAVIS_BUILD_DIR\\vcpkg\\scripts\\buildsystems\\vcpkg.cmake ..
cmake --build . --target install

cd ..
rm -r td


# Copy artifacts
cp bin/libtdjni.dll $TRAVIS_BUILD_DIR/out
