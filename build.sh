#!/bin/bash

# build libde265, x265-git, aom, libwebp (libsharpyuv), svt-av1, zlib, libheif

SRC=$(realpath $(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd))

set -e

declare -A REPOS=(
  [libde265]="https://github.com/strukturag/libde265/archive/refs/tags/v1.0.15.tar.gz 841c77a583f3ad82d5590b775c48a144"
  [x265]="https://bitbucket.org/multicoreware/x265_git/get/3.5.tar.gz bb92a1fdcb4f4530c3fc12de3452d7fb"
  [aom]="https://aomedia.googlesource.com/aom/+archive/v3.8.1.tar.gz none"
  [libwebp]="https://github.com/webmproject/libwebp/archive/refs/tags/v1.3.2.tar.gz 827d510b73c73fca3343140556dd2943"
  [svt]="https://gitlab.com/AOMediaCodec/SVT-AV1/-/archive/v1.8.0/v1.8.0.tar.gz 76ce1106bb81821a6d54ecde86d95161"
  [zlib]="https://github.com/madler/zlib/archive/refs/tags/v1.3.1.tar.gz ddb17dbbf2178807384e57ba0d81e6a1"
  [libheif]="https://github.com/strukturag/libheif/archive/refs/tags/v1.17.6.tar.gz 2c8d3eedfd238a05311533f45ebfac5c"
)

BUILDS="libde265 x265 aom libwebp svt zlib libheif"
CLEAN=0
EXIT=0
CACHE=$SRC/.cache
BUILD_DIR=$SRC/build
DIST_DIR=
SVT=ON
DUMP=

OPTIND=1
while getopts "b:cC:d:p:s:D:x" opt; do
case "$opt" in
  b) BUILDS=$OPTARG ;;
  c) CLEAN=1 ;;
  C) CACHE=$OPTARG ;;
  d) BUILD_DIR=$OPTARG ;;
  p) DIST_DIR=$OPTARG ;;
  s) SVT=$(tr '[a-z]' '[A-Z]' <<< "$OPTARG") ;;
  D) DUMP=$(realpath "$OPTARG") ;;
  x) EXIT=1 ;;
esac
done

mkdir -p $CACHE $BUILD_DIR

if [ -z "$DIST_DIR" ]; then
  DIST_DIR=$(realpath $BUILD_DIR/dist)
fi

urlver() {
  basename "$1" \
    | sed \
      -e 's/\.tar\.gz$//' \
      -e 's/^v\?//'
}

repourl() {
  awk '{print $1}' <<< "${REPOS[$1]}"
}

repohash() {
  awk '{print $2}' <<< "${REPOS[$1]}"
}

repofile() {
  echo $CACHE/$1-$(urlver "$(repourl "$1")").tar.gz
}

relname() {
  sed -e "s%^$PWD/%%" <<< "$1"
}

grab() {
  echo "RETRIEVING: $1 -> $(relname "$2")"
  curl -4 -L -# -o $2 $1
}

for build in $BUILDS; do
  # cache
  file=$(repofile $build)
  if [[ ! -e "$file" || "$CLEAN" = "1" ]]; then
    grab "$(repourl $build)" "$file"
  fi

  # verify
  sum=$(repohash $build) s=$(md5sum "$file"|awk '{print $1}')
  if [[ "$sum" != "none" && "$sum" != "$s" ]]; then
    echo "error: $(relname "$file") does not have hash $sum, has $s"
    exit 1
  else
    echo "VALID: $(relname "$file") ($sum)"
  fi
done

# extract
for build in $BUILDS; do
  dest=$BUILD_DIR/$build
  file=$(repofile $build)
  if [[ ! -e "$dest" || "$CLEAN" != "0" ]]; then
    echo "EXTRACTING: $(relname "$file") -> $(relname "$dest")"
    rm -f $dest
    if [ "$build" = "aom" ]; then
      mkdir -p $dest
      tar -C $dest -zxf $file
    else
      tmpdir=$(mktemp -d /tmp/heif-$build.XXXX)
      tar -C $tmpdir -zxf $file
      mv $tmpdir/* $dest
    fi
  fi
done

if [ ! -z "$DUMP" ]; then
  echo "DUMPING: $DUMP"
  pushd $BUILD_DIR/libheif &> /dev/null
  cmake --preset release-noplugins -N|sed 1,2d > $DUMP
  popd &> /dev/null
  perl -pi -e 's/^\s*//' $DUMP
  perl -pi -e 's/"//g' $DUMP
  cat $DUMP
  exit
fi

if [ "$EXIT" = "1" ]; then
  exit
fi

build_vars() {
  while read line; do
    echo -n "-D$line "
  done < "$1"
  for pkg in LIBDE265 X265 AOM LIBSHARPYUV SvtEnc ZLIB; do
    extra=""
    if [ "$pkg" = "LIBSHARPYUV" ]; then
      extra="/webp"
    fi
    echo -n "-D${pkg}_INCLUDE_DIR=$DIST_DIR/include$extra -D${pkg}_LIBRARY=$DIST_DIR/lib/*.a "
  done
}

build_libde265() {
  local extra=''
  if [ ! -z "$CROSS_TRIPLE" ]; then
    extra="--host=$CROSS_TRIPLE"
  fi
  pushd $1 &> /dev/null
  (set -x;
    ./autogen.sh
    ./configure \
      --prefix="$DIST_DIR" \
      --enable-static \
      --disable-shared \
      --disable-dec265 \
      --disable-sherlock265 \
      $extra
    make -j$((`nproc`+2)) install
  )
  popd &> /dev/null
}

build_x265() {
  mkdir -p $1/build
  pushd $1 &> /dev/null
  (set -x;
    cmake \
      -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="$DIST_DIR" \
      -DENABLE_SHARED=OFF \
      -S ./source \
      -B ./build
    ninja -C ./build install
  )
  popd &> /dev/null
}

build_aom() {
  mkdir -p $1/build
  pushd $1 &> /dev/null
  (set -x;
    cmake \
      -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="$DIST_DIR" \
      -DENABLE_DOCS=0 \
      -DENABLE_EXAMPLES=0 \
      -DENABLE_TESTDATA=0 \
      -DENABLE_TESTS=0 \
      -DENABLE_TOOLS=0 \
      -B ./build
    ninja -C ./build install
  )
  popd &> /dev/null
}

build_libwebp() {
  mkdir -p $1/build
  pushd $1 &> /dev/null
  (set -x;
    cmake \
      -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="$DIST_DIR" \
      -DBUILD_SHARED_LIBS=OFF \
      -B ./build
    ninja -C ./build install
  )
  popd &> /dev/null
}

build_svt() {
  if [ "$SVT" != "ON" ]; then
    return
  fi
  mkdir -p $1/build
  pushd $1 &> /dev/null
  (set -x;
    cmake \
      -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="$DIST_DIR" \
      -DBUILD_SHARED_LIBS=OFF \
      -DBUILD_DEC=OFF \
      -DBUILD_APPS=OFF \
      -B ./build
    ninja -C ./build install
  )
  popd &> /dev/null
}

build_zlib() {
  pushd $1 &> /dev/null
  (set -x;
    ./configure \
      --prefix="$DIST_DIR" \
      --static
    make -j$((`nproc`+2)) install
  )
  popd &> /dev/null
}

build_libheif() {
  # hack for windows preset issue
  local preset="--preset release-noplugins"
  if [[ "$CROSS_TRIPLE" =~ "w64" ]]; then
    preset=$(build_vars $CACHE/linux_amd64.preset)
  fi

  mkdir -p $1/build
  pushd $1 &> /dev/null
  (set -x;
    PKG_CONFIG_PATH=$DIST_DIR/lib/pkgconfig \
    cmake \
      $preset \
      -G "Ninja" \
      -DCMAKE_INSTALL_PREFIX="$DIST_DIR" \
      -DBUILD_SHARED_LIBS=OFF \
      -DBUILD_TESTING=OFF \
      -DWITH_EXAMPLES=OFF \
      -DWITH_GDK_PIXBUF=OFF \
      -DWITH_SvtEnc="$SVT" \
      -B ./build
    ninja -C ./build install
  )
  popd &> /dev/null
}

# build
for build in $BUILDS; do
  echo "BUILDING: $build"
  eval "build_$build" "$(realpath $BUILD_DIR/$build)"
done