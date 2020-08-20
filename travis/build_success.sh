#!/bin/bash -e
set -e

# ====== Setup environment variables
source ./travis/setup_variables.sh

# ====== Copy build output
if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
  mv $TDNATIVES_BIN_DIR/$SRC_TDJNI_LIBNAME $TRAVIS_BUILD_DIR/out/$DEST_TDJNI_LIBNAME
  mv $TDNATIVES_DOCS_BIN_DIR $TRAVIS_BUILD_DIR/out/docs
elif [[ "$TRAVIS_OS_NAME" == "windows" ]]; then
  mv $TDNATIVES_BIN_DIR/$SRC_TDJNI_LIBNAME $TRAVIS_BUILD_DIR/out/$DEST_TDJNI_LIBNAME
fi

# ====== Deploy phase

# Setup ssh
[ -d ~/.ssh ] || mkdir -p ~/.ssh
echo "$GIT_IGN_TRAVIS_DEPLOY_PRIVATE_KEY" | base64 -d > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa || true
ssh-keyscan ssh.git.ignuranza.net >> $HOME/.ssh/known_hosts
ssh-keyscan git.ignuranza.net >> $HOME/.ssh/known_hosts

# Setup user
git config --global user.email "andrea@cavallium.it"
git config --global user.name "Andrea Cavalli"
git config pull.rebase false

# Prepare repository
cd $TRAVIS_BUILD_DIR
git clone --branch tdlib --depth=1 "git@ssh.git.ignuranza.net:tdlight-team/tdlight-java-natives-$TRAVIS_OS_NAME_STANDARD-$TRAVIS_CPU_ARCH_STANDARD.git"
cd "tdlight-java-natives-$TRAVIS_OS_NAME_STANDARD-$TRAVIS_CPU_ARCH_STANDARD"
[ -d "src/main/resources/libs/$TRAVIS_OS_NAME_SHORT/$TRAVIS_CPU_ARCH_STANDARD" ] || mkdir -p "src/main/resources/libs/$TRAVIS_OS_NAME_SHORT/$TRAVIS_CPU_ARCH_STANDARD"
# Add the folder to git if not added
mv "$TRAVIS_BUILD_DIR/out/$DEST_TDJNI_LIBNAME" "src/main/resources/libs/$TRAVIS_OS_NAME_SHORT/$TRAVIS_CPU_ARCH_STANDARD/$DEST_TDJNI_LIBNAME"

# IF THE NATIVE LIBRARY IS CHANGED
git add "src"
git add "src/main/resources/libs/$TRAVIS_OS_NAME_SHORT/$TRAVIS_CPU_ARCH_STANDARD"
git status --porcelain
echo "File observed: $(git status --porcelain | grep "src/main/resources/libs/$TRAVIS_OS_NAME_SHORT/$TRAVIS_CPU_ARCH_STANDARD/$DEST_TDJNI_LIBNAME")"
if [[ ! -z "$(git status --porcelain | grep "src/main/resources/libs/$TRAVIS_OS_NAME_SHORT/$TRAVIS_CPU_ARCH_STANDARD/$DEST_TDJNI_LIBNAME")" ]]; then
    # Do the upgrade of the repository
    git add "src/main/resources/libs/$TRAVIS_OS_NAME_SHORT/$TRAVIS_CPU_ARCH_STANDARD/$DEST_TDJNI_LIBNAME"
    mvn build-helper:parse-version versions:set \
    -DnewVersion=\${parsedVersion.majorVersion}.\${parsedVersion.minorVersion}.\${parsedVersion.nextIncrementalVersion} \
    versions:commit
    NEW_VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
    git add pom.xml
    git commit -m "Updated native library"
    git tag -a "v$NEW_VERSION-td" -m "Version $NEW_VERSION"
    git push origin "v$NEW_VERSION-td"
    git push
    mvn -B -V deploy

    # Upgrade the dependency of tdlight-java
    cd $TRAVIS_BUILD_DIR
    [ -d tdlight-java ] && sudo rm -rf --interactive=never tdlight-java
    git clone --depth=1 -b td-master --single-branch git@ssh.git.ignuranza.net:tdlight-team/tdlight-java.git
    git submodule update --remote --init --recursive
    cd $TRAVIS_BUILD_DIR/tdlight-java
    git checkout td-master
    mvn versions:use-latest-releases -Dincludes=it.tdlight:tdlib-natives-$TRAVIS_OS_NAME_STANDARD-$TRAVIS_CPU_ARCH_STANDARD
    [ -f pom.xml.versionsBackup ] && rm pom.xml.versionsBackup
    git add pom.xml
    git commit -m "Upgrade $TRAVIS_OS_NAME_STANDARD-$TRAVIS_CPU_ARCH_STANDARD natives"
    git push
else
    echo "Binaries are already updated."
fi

if [ "$TRAVIS_OS_NAME_STANDARD" = "linux" ]; then
    if [ "$TRAVIS_CPU_ARCH" = "amd64" ]; then

        # Patch TdApi.java
        echo "Patching TdApi.java"
        cd $TDLIB_SERIALIZER_DIR
        python3 $TDLIB_SERIALIZER_DIR $JAVA_SRC_DIR/it/tdlight/tdlib/TdApi.java $JAVA_SRC_DIR/it/tdlight/tdlib/new_TdApi.java $TDLIB_SERIALIZER_DIR/headers.txt
        rm $JAVA_SRC_DIR/it/tdlight/tdlib/TdApi.java
        unexpand --tabs=2 $JAVA_SRC_DIR/it/tdlight/tdlib/new_TdApi.java > $JAVA_SRC_DIR/it/tdlight/tdlib/TdApi.java
        rm $JAVA_SRC_DIR/it/tdlight/tdlib/new_TdApi.java

           # Upgrade the file of tdlight-java
        cd $TRAVIS_BUILD_DIR
        [ -d tdlight-java ] && sudo rm -rf --interactive=never tdlight-java
        git clone --depth=1 -b td-master --single-branch git@ssh.git.ignuranza.net:tdlight-team/tdlight-java.git
        git submodule update --remote --init --recursive
        cd $TRAVIS_BUILD_DIR/tdlight-java
        git checkout td-master
        cp $JAVA_SRC_DIR/it/tdlight/tdlib/TdApi.java $TRAVIS_BUILD_DIR/tdlight-java/src/main/java/it/tdlight/tdlib/TdApi.java

        # IF TdApi.java IS CHANGED
        cd $TRAVIS_BUILD_DIR/tdlight-java
        git add "src/main/java/it/tdlight/tdlib/TdApi.java"
        git status --porcelain
        echo "File observed: $(git status --porcelain | grep "src/main/java/it/tdlight/tdlib/TdApi.java")"
        if [[ ! -z "$(git status --porcelain | grep "src/main/java/it/tdlight/tdlib/TdApi.java")" ]]; then
            # Upgrade TdApi.java in repository master
            cd $TRAVIS_BUILD_DIR/tdlight-java
            git add src/main/java/it/tdlight/tdlib/TdApi.java
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
echo "Finished."
