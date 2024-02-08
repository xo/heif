#!/bin/bash

set -e

SRC=$(realpath $(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd))

NAME="$(basename $SRC).test"
FORCE=false
VERBOSE=false
PLATFORM=$(go env GOOS)
ARCH=$(go env GOARCH)
GOARCH=$ARCH

TAGS=(
)

OPTIND=1
while getopts "a:fxt:" opt; do
case "$opt" in
  a) ARCH=$OPTARG ;;
  f) FORCE=true ;;
  x) VERBOSE=true ;;
  t) TAGS=($OPTARG) ;;
esac
done

BUILD=$SRC/build
DIR=$BUILD/$PLATFORM/$ARCH

TAR=tar
EXT=tar.bz2
BIN=$DIR/$NAME

OUT=$DIR

CARCH=
QEMUARCH=
GNUTYPE=
CC=
CXX=
EXTLD=g++

if [[ "$PLATFORM" == "linux" && "$ARCH" != "$GOARCH" ]]; then
  case $ARCH in
    arm)   CARCH=armhf   QEMUARCH=arm     GNUTYPE=gnueabihf ;;
    arm64) CARCH=aarch64 QEMUARCH=aarch64 GNUTYPE=gnu ;;
    *)
      echo "error: unknown arch $ARCH"
      exit 1
    ;;
  esac
  LDARCH=$CARCH
  if [[ "$ARCH" == "arm" ]]; then
    if [ -d /usr/arm-linux-$GNUTYPE ]; then
      LDARCH=arm
    elif [ -d /usr/arm-none-linux-$GNUTYPE ]; then
      LDARCH=arm-none
    fi
  fi
  CC=$LDARCH-linux-$GNUTYPE-gcc
  CXX=$LDARCH-linux-$GNUTYPE-c++
  EXTLD=$LDARCH-linux-$GNUTYPE-g++
fi

LDFLAGS=(
  -s
  -w
)

TAGS="${TAGS[@]}"
LDFLAGS="${LDFLAGS[@]}"

echo "APP:         $NAME ($PLATFORM/$ARCH)"
echo "BUILD TAGS:  $TAGS"
echo "LDFLAGS:     $LDFLAGS"

pushd $SRC &> /dev/null

if [ -f $OUT ]; then
  echo "REMOVING:    $OUT"
  rm -rf $OUT
fi
mkdir -p $DIR
echo "BUILDING:    $BIN"

# build
echo "BUILD:"

(set -x;
  CC=$CC \
  CXX=$CXX \
  CGO_ENABLED=1 \
  GOARCH=$ARCH \
  go test \
    -v=$VERBOSE \
    -x=$VERBOSE \
    -tags="$TAGS" \
    -c \
    -o $BIN
)

(set -x;
  file $BIN
)
if [[ "$PLATFORM" != "windows" ]]; then
  (set -x;
    chmod +x $BIN
  )
fi

# purge disk cache
if [[ "$PLATFORM" == "darwin" && "$CI" == "true" ]]; then
  (set -x;
    sudo /usr/sbin/purge
  )
fi

popd &> /dev/null
