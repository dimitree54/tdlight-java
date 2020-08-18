#!/bin/bash -e
echo "Deployed"
echo "$TRAVIS_OS_NAME"
ls -alch $TRAVIS_BUILD_DIR/out
ls -alch $TRAVIS_BUILD_DIR
