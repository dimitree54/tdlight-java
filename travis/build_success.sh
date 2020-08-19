#!/bin/bash -e
set -e

# ====== Setup environment variables
./setup_variables.sh

# ====== Copy build output
if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
  mv $TDNATIVES_BIN_DIR/libtdjni.so $TRAVIS_BUILD_DIR/out/libtdjni.so
  mv $TDNATIVES_DOCS_BIN_DIR $TRAVIS_BUILD_DIR/out/docs
elif [[ "$TRAVIS_OS_NAME" == "windows" ]]; then
  mv $TDNATIVES_BIN_DIR/tdjni.dll $TRAVIS_BUILD_DIR/out/libtdjni.dll
fi

# ====== Deploy phase

# Setup ssh
mkdir -p ~/.ssh
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
git clone --depth=1 "git@ssh.git.ignuranza.net:tdlight-team/tdlight-java-natives-$TRAVIS_OS_NAME_STANDARD-$TRAVIS_CPU_ARCH_STANDARD.git"
cd "tdlight-java-natives-$TRAVIS_OS_NAME_STANDARD-$TRAVIS_CPU_ARCH_STANDARD"
mkdir -p "src/main/resources/libs/$TRAVIS_OS_NAME_SHORT/$TRAVIS_CPU_ARCH_STANDARD"
mv "$TRAVIS_BUILD_DIR/out/$SRC_TDJNI_LIBNAME" "src/main/resources/libs/$TRAVIS_OS_NAME_SHORT/$TRAVIS_CPU_ARCH_STANDARD/$DEST_TDJNI_LIBNAME"

# IF THE NATIVE LIBRARY IS CHANGED
if [[ ! -z "$(git status --porcelain | grep "src/main/resources/libs/$TRAVIS_OS_NAME_SHORT/$TRAVIS_CPU_ARCH_STANDARD/$DEST_TDJNI_LIBNAME")" ]]; then
    # Do the upgrade of the repository
    git add "src/main/resources/libs/$TRAVIS_OS_NAME_SHORT/$TRAVIS_CPU_ARCH_STANDARD/$DEST_TDJNI_LIBNAME"
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
	[ -d tdlight-java ] && sudo rm -rf --interactive=never tdlight-java
    git clone --depth=1 -b master --single-branch git@ssh.git.ignuranza.net:tdlight-team/tdlight-java.git
	cd $TRAVIS_BUILD_DIR/tdlight-java
	git checkout master
    mvn versions:use-latest-releases -Dincludes=it.tdlight:tdlight-natives-$TRAVIS_OS_NAME_STANDARD-$TRAVIS_CPU_ARCH_STANDARD
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
        python3 $TDLIB_SERIALIZER_DIR $JAVA_SRC_DIR/it/tdlight/tdnatives/TdApi.java $JAVA_SRC_DIR/it/tdlight/tdnatives/new_TdApi.java $TDLIB_SERIALIZER_DIR/headers.txt
        rm $JAVA_SRC_DIR/it/tdlight/tdnatives/TdApi.java
        unexpand --tabs=2 $JAVA_SRC_DIR/it/tdlight/tdnatives/new_TdApi.java > $JAVA_SRC_DIR/it/tdlight/tdnatives/TdApi.java
        rm $JAVA_SRC_DIR/it/tdlight/tdnatives/new_TdApi.java

   		# Upgrade the file of tdlight-java
		cd $TRAVIS_BUILD_DIR
		[ -d tdlight-java ] && sudo rm -rf --interactive=never tdlight-java
    	git clone --depth=1 -b master --single-branch git@ssh.git.ignuranza.net:tdlight-team/tdlight-java.git
        cd $TRAVIS_BUILD_DIR/tdlight-java
		git checkout master
        cp $JAVA_SRC_DIR/it/tdlight/tdnatives/TdApi.java $TRAVIS_BUILD_DIR/tdlight-java/src/main/java/it/tdlight/tdnatives/TdApi.java

        # IF TdApi.java IS CHANGED
		if [[ ! -z "$(git status --porcelain | grep "$JAVA_SRC_DIR/it/tdlight/tdnatives/TdApi.java")" ]]; then
            # Upgrade TdApi.java in repository master
			cd $TRAVIS_BUILD_DIR/tdlight-java
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
