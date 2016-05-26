#!/bin/bash

# URLS

TT_SWIFTENV_URL="https://github.com/kylef/swiftenv.git"
TT_GCD_URL="https://github.com/apple/swift-corelibs-libdispatch.git"

TT_GCD_SWIFT3_BRANCH=experimental/foundation

# swiftenv

git clone --depth 1 ${TT_SWIFTENV_URL} ~/.swiftenv

export SWIFTENV_ROOT="$HOME/.swiftenv"
export PATH="${SWIFTENV_ROOT}/bin:${SWIFTENV_ROOT}/shims:$PATH"


# Install Swift

swiftenv install ${SWIFT_SNAPSHOT_NAME}


# Environment

TT_SWIFT_BINARY=`swiftenv which swift`
TT_SNAP_DIR=`echo $TT_SWIFT_BINARY | sed "s|/usr/bin/swift||g"`


# Install GCD

if [[ "$TRAVIS_OS_NAME" == "Linux" ]]; then
  # GCD prerequisites
  sudo apt-get install autoconf libtool pkg-config \
       libblocksruntime-dev \
       libkqueue-dev \
       libpthread-workqueue-dev \
       systemtap-sdt-dev \
       libbsd-dev libbsd0 libbsd0-dbg
  
  git clone --recursive ${TT_GCD_URL} gcd-${SWIFT_SNAPSHOT_NAME}
  cd gcd-${SWIFT_SNAPSHOT_NAME}
  git checkout ${TT_GCD_SWIFT3_BRANCH}
  git pull
  ./autogen.sh
  
  ./configure --with-swift-toolchain=${TT_SNAP_DIR}/usr --prefix=${TT_SNAP_DIR}/usr
  make
  make install
fi

if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
  echo ${TT_SWIFT_BINARY}
  find /Library/Developer/Toolchains
  find ${SWIFTENV_ROOT}  
fi
