#!/bin/bash -e

# Setup variables
export MAVEN_OPTS="--add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.base/java.lang.reflect=ALL-UNNAMED --add-opens java.base/javax.crypto=ALL-UNNAMED --add-opens java.base/java.io=ALL-UNNAMED"

if [ "$TRAVIS_CPU_ARCH" = "arm64" ]; then
    export TRAVIS_CPU_ARCH_STANDARD="aarch64"
else
    export TRAVIS_CPU_ARCH_STANDARD="${TRAVIS_CPU_ARCH,,}"
fi
export TRAVIS_OS_NAME_STANDARD="${TRAVIS_OS_NAME,,}"

echo "TRAVIS_OS_NAME: $TRAVIS_OS_NAME"
echo "TRAVIS_OS_NAME_STANDARD: $TRAVIS_OS_NAME_STANDARD"
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

# Update repo
git clone "git@ssh.git.ignuranza.net:tdlight-team/tdlight-java-natives-$TRAVIS_OS_NAME_STANDARD-$TRAVIS_CPU_ARCH_STANDARD.git"
cd "tdlight-java-natives-$TRAVIS_OS_NAME_STANDARD-$TRAVIS_CPU_ARCH_STANDARD"
if [ "$TRAVIS_OS_NAME_STANDARD" = "windows" ]; then
    mkdir -p "src/main/resources/libs/$TRAVIS_OS_NAME_STANDARD/$TRAVIS_CPU_ARCH_STANDARD"
    mv "$TRAVIS_BUILD_DIR/out/libtdjni.so" "src/main/resources/libs/$TRAVIS_OS_NAME_STANDARD/$TRAVIS_CPU_ARCH_STANDARD/tdjni.dll"
    git add "src/main/resources/libs/$TRAVIS_OS_NAME_STANDARD/$TRAVIS_CPU_ARCH_STANDARD/tdjni.dll"
else
    mkdir -p "src/main/resources/libs/$TRAVIS_OS_NAME_STANDARD/$TRAVIS_CPU_ARCH_STANDARD"
    mv "$TRAVIS_BUILD_DIR/out/libtdjni.so" "src/main/resources/libs/$TRAVIS_OS_NAME_STANDARD/$TRAVIS_CPU_ARCH_STANDARD/tdjni.so"
    git add "src/main/resources/libs/$TRAVIS_OS_NAME_STANDARD/$TRAVIS_CPU_ARCH_STANDARD/tdjni.so"
fi
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
ls -alch

ls -alch $TRAVIS_BUILD_DIR/out
ls -alch $TRAVIS_BUILD_DIR
