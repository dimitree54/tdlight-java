#!/bin/bash -e
set -e

# ====== Setup environment variables
echo "Setup variabled."
source ./travis/setup_variables.sh
echo "Setup variables. OK"

# ====== Copy build output
  mv $TDNATIVES_BIN_DIR/$SRC_TDJNI_LIBNAME $TRAVIS_BUILD_DIR/out/$DEST_TDJNI_LIBNAME
if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
  mv $TDNATIVES_DOCS_BIN_DIR $TRAVIS_BUILD_DIR/out/docs
fi

# ====== Deploy phase

# Setup ssh
echo "Setup ssh."
[ -d ~/.ssh ] || mkdir -p ~/.ssh
echo "$GIT_IGN_TRAVIS_DEPLOY_PRIVATE_KEY" | base64 --decode > ~/.ssh/id_rsa || true
chmod 600 ~/.ssh/id_rsa || true
ssh-keyscan ssh.git.ignuranza.net >> $HOME/.ssh/known_hosts || true
ssh-keyscan git.ignuranza.net >> $HOME/.ssh/known_hosts || true
echo "Setup ssh. OK"

# Setup user
echo "Setup git user."
git config --global user.email "andrea@cavallium.it"
git config --global user.name "Andrea Cavalli"
git config pull.rebase false
echo "Setup git user. OK"

# Prepare repository
echo "Setup repository."
cd $TRAVIS_BUILD_DIR
git clone --depth=1 "git@ssh.git.ignuranza.net:tdlight-team/tdlight-java-natives-$TRAVIS_OS_NAME_STANDARD-$TRAVIS_CPU_ARCH_STANDARD.git"
cd "tdlight-java-natives-$TRAVIS_OS_NAME_STANDARD-$TRAVIS_CPU_ARCH_STANDARD"
[ -d "src/main/resources/libs/$TRAVIS_OS_NAME_SHORT/$TRAVIS_CPU_ARCH_STANDARD" ] || mkdir -p "src/main/resources/libs/$TRAVIS_OS_NAME_SHORT/$TRAVIS_CPU_ARCH_STANDARD"
# Add the folder to git if not added
mv "$TRAVIS_BUILD_DIR/out/$DEST_TDJNI_LIBNAME" "src/main/resources/libs/$TRAVIS_OS_NAME_SHORT/$TRAVIS_CPU_ARCH_STANDARD/$DEST_TDJNI_LIBNAME"
echo "Setup repository. OK"

# IF THE NATIVE LIBRARY IS CHANGED
echo "Checking natives changed."
git add "src" || true
git add "src/main/resources/libs/$TRAVIS_OS_NAME_SHORT/$TRAVIS_CPU_ARCH_STANDARD" || true
git status --porcelain
echo "File observed: $(git status --porcelain | grep "src/main/resources/libs/$TRAVIS_OS_NAME_SHORT/$TRAVIS_CPU_ARCH_STANDARD/$DEST_TDJNI_LIBNAME")"
echo "Checking natives changed. OK"
if [[ ! -z "$(git status --porcelain | grep "src/main/resources/libs/$TRAVIS_OS_NAME_SHORT/$TRAVIS_CPU_ARCH_STANDARD/$DEST_TDJNI_LIBNAME")" ]]; then
    # Do the upgrade of the repository
    echo "Upgrade repository."
    git add "src/main/resources/libs/$TRAVIS_OS_NAME_SHORT/$TRAVIS_CPU_ARCH_STANDARD/$DEST_TDJNI_LIBNAME" || true
    mvn build-helper:parse-version versions:set \
    -DnewVersion=\${parsedVersion.majorVersion}.\${parsedVersion.minorVersion}.\${parsedVersion.nextIncrementalVersion} \
    versions:commit
    NEW_VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
    git add pom.xml
    git commit -m "Updated native library"
    git tag -a "v$NEW_VERSION" -m "Version $NEW_VERSION"
    git push origin "v$NEW_VERSION"
    git push
    mvn -B -V deploy -P publish-to-mchv
    mvn -B -V deploy -P publish-to-github

    # Upgrade the dependency of tdlight-java
    cd $TRAVIS_BUILD_DIR
    [ -d tdlight-java ] && sudo rm -rf --interactive=never tdlight-java
    git clone --depth=1 -b master --single-branch git@ssh.git.ignuranza.net:tdlight-team/tdlight-java.git
    git submodule update --remote --init --recursive
    cd $TRAVIS_BUILD_DIR/tdlight-java
    git checkout master
    mvn versions:use-latest-releases -Dincludes=it.tdlight:tdlight-natives-$TRAVIS_OS_NAME_STANDARD-$TRAVIS_CPU_ARCH_STANDARD
    [ -f pom.xml.versionsBackup ] && rm pom.xml.versionsBackup
    git add pom.xml
    git commit -m "Upgrade $TRAVIS_OS_NAME_STANDARD-$TRAVIS_CPU_ARCH_STANDARD natives"
    git push
    echo "Upgrade repository. OK"
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
        git clone --depth=1 -b master --single-branch git@ssh.git.ignuranza.net:tdlight-team/tdlight-java.git
        git submodule update --remote --init --recursive
        cd $TRAVIS_BUILD_DIR/tdlight-java
        git checkout master
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
