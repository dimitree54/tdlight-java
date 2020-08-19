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

if [ "$TRAVIS_OS_NAME" = "windows" ]; then
    export PATH="$PATH:/c/Program Files/OpenJDK/openjdk-11.0.8_10/bin:/c/ProgramData/chocolatey/lib/maven/apache-maven-3.6.3/bin:/c/ProgramData/chocolatey/lib/base64/tools"
    export JAVA_HOME="/c/Program Files/OpenJDK/openjdk-11.0.8_10"
    export JAVA_INCLUDE_PATH="/c/Program Files/OpenJDK/openjdk-11.0.8_10/include"
else
    export PATH="$PATH:/usr/lib/jvm/java-11-openjdk-$(dpkg --print-architecture)/bin"
    export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-$(dpkg --print-architecture)"
    export JAVA_INCLUDE_PATH="/usr/lib/jvm/java-11-openjdk-$(dpkg --print-architecture)/include"
fi
export MAVEN_OPTS="--add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.base/java.lang.reflect=ALL-UNNAMED --add-opens java.base/javax.crypto=ALL-UNNAMED --add-opens java.base/java.io=ALL-UNNAMED"

if [ "$TRAVIS_CPU_ARCH" = "arm64" ]; then
    export TRAVIS_CPU_ARCH_STANDARD="aarch64"
else
    export TRAVIS_CPU_ARCH_STANDARD="${TRAVIS_CPU_ARCH,,}"
fi
export TRAVIS_OS_NAME_STANDARD="${TRAVIS_OS_NAME,,}"
if [ "$TRAVIS_OS_NAME_STANDARD" = "windows" ]; then
	export TRAVIS_OS_NAME_SHORT="win"
else
	export TRAVIS_OS_NAME_SHORT=$TRAVIS_OS_NAME_STANDARD
fi

echo "TRAVIS_OS_NAME: $TRAVIS_OS_NAME"
echo "TRAVIS_OS_NAME_STANDARD: $TRAVIS_OS_NAME_STANDARD"
echo "TRAVIS_OS_NAME_SHORT: $TRAVIS_OS_NAME_SHORT"
echo "TRAVIS_CPU_ARCH: $TRAVIS_CPU_ARCH"
echo "TRAVIS_CPU_ARCH_STANDARD: $TRAVIS_CPU_ARCH_STANDARD"
# End setup variables

# Setup ssh
mkdir -p ~/.ssh
echo "$GIT_IGN_TRAVIS_DEPLOY_PRIVATE_KEY" | base64 -d > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa || true
ssh-keyscan ssh.git.ignuranza.net >> $HOME/.ssh/known_hosts
ssh-keyscan git.ignuranza.net >> $HOME/.ssh/known_hosts

# Setup user
git config --global user.email "andrea@cavallium.it"
git config --global user.name "Andrea Cavalli"

# Prepare repository
cd $TRAVIS_BUILD_DIR
git clone "git@ssh.git.ignuranza.net:tdlight-team/tdlight-java-natives-$TRAVIS_OS_NAME_STANDARD-$TRAVIS_CPU_ARCH_STANDARD.git"
cd "tdlight-java-natives-$TRAVIS_OS_NAME_STANDARD-$TRAVIS_CPU_ARCH_STANDARD"
SRC_LIBNAME=""
LIBNAME=""
if [ "$TRAVIS_OS_NAME_STANDARD" = "windows" ]; then
    SRC_LIBNAME="libtdjni.dll"
    LIBNAME="tdjni.dll"
else
    SRC_LIBNAME="libtdjni.so"
    LIBNAME="tdjni.so"
fi
mkdir -p "src/main/resources/libs/$TRAVIS_OS_NAME_SHORT/$TRAVIS_CPU_ARCH_STANDARD"
mv "$TRAVIS_BUILD_DIR/out/$SRC_LIBNAME" "src/main/resources/libs/$TRAVIS_OS_NAME_SHORT/$TRAVIS_CPU_ARCH_STANDARD/$LIBNAME"

# IF THE NATIVE LIBRARY IS CHANGED
if ! (git diff --exit-code "src/main/resources/libs/$TRAVIS_OS_NAME_SHORT/$TRAVIS_CPU_ARCH_STANDARD/$LIBNAME"); then
    # Do the upgrade of the repository
    git add "src/main/resources/libs/$TRAVIS_OS_NAME_SHORT/$TRAVIS_CPU_ARCH_STANDARD/$LIBNAME"
    mvn build-helper:parse-version versions:set \
    -DnewVersion=\${parsedVersion.majorVersion}.\${parsedVersion.minorVersion}.\${parsedVersion.nextIncrementalVersion} \
    versions:commit
    NEW_VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
    git add pom.xml
    git commit -m "Updated native library"
    git tag -a "v$NEW_VERSION" -m "Version $NEW_VERSION"
    git push origin "v$NEW_VERSION"
    git push
    mvn -B -V deploy

    # Upgrade the dependency of tdlight-java
    cd $TRAVIS_BUILD_DIR
    git clone -b master --single-branch git@ssh.git.ignuranza.net:tdlight-team/tdlight-java.git
    cd tdlight-java
    mvn versions:use-latest-releases -Dincludes=it.tdlight:tdlight-natives-$TRAVIS_OS_NAME_STANDARD-$TRAVIS_CPU_ARCH_STANDARD
    rm pom.xml.versionsBackup
    git add pom.xml
    git commit -m "Upgrade $TRAVIS_OS_NAME_STANDARD-$TRAVIS_CPU_ARCH_STANDARD natives"
    git push
else
    echo "Binaries are already updated."
fi

if [ "$TRAVIS_OS_NAME_STANDARD" = "linux" ]; then
    if [ "$TRAVIS_CPU_ARCH" = "amd64" ]; then

        # ====== Patch TdApi.java
        echo "Patching TdApi.java"
        python3 $TDLIB_SERIALIZER_DIR $JAVA_SRC_DIR/it/tdlight/tdnatives/TdApi.java $JAVA_SRC_DIR/it/tdlight/tdnatives/new_TdApi.java $TDLIB_SERIALIZER_DIR/headers.txt
        rm $JAVA_SRC_DIR/it/tdlight/tdnatives/TdApi.java
        unexpand --tabs=2 $JAVA_SRC_DIR/it/tdlight/tdnatives/new_TdApi.java > $JAVA_SRC_DIR/it/tdlight/tdnatives/TdApi.java
        rm $JAVA_SRC_DIR/it/tdlight/tdnatives/new_TdApi.java
        
        cd $TRAVIS_BUILD_DIR/tdlight-java
        git pull
        cp $JAVA_SRC_DIR/it/tdlight/tdnatives/TdApi.java src/main/java/it/tdlight/tdnatives/TdApi.java

        # IF TdApi.java IS CHANGED
        if ! (git diff --exit-code "$JAVA_SRC_DIR/it/tdlight/tdnatives/TdApi.java"); then
            # Upgrade TdApi.java in repository master
            git add src/main/java/it/tdlight/tdnatives/TdApi.java
            git commit -m "Upgraded TdApi.java"
            git push
        else
            echo "TdApi.java already updated."
        fi
    else
        echo "Don't update TdApi.java."
    fi
else
    echo "Don't update TdApi.java."
fi
