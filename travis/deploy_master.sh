#!/bin/bash -e
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

echo "$GIT_IGN_TRAVIS_DEPLOY_PRIVATE_KEY" > ~/.ssh/id_rsa

git clone "git@ssh.git.ignuranza.net:tdlight-team/tdlight-java-natives-$TRAVIS_OS_NAME_STANDARD-$TRAVIS_CPU_ARCH_STANDARD.git"
cd "tdlight-java-natives-$TRAVIS_OS_NAME_STANDARD-$TRAVIS_CPU_ARCH_STANDARD"
ls -alch

ls -alch $TRAVIS_BUILD_DIR/out
ls -alch $TRAVIS_BUILD_DIR
