#!/bin/bash

set -e

export PATH=/bin:/sbin:/usr/bin:/usr/sbin

PACKAGE_NAME=$(basename "$1" .zip)
OUTPUT_PATH=$(pwd)/"$2"

EXPECTED_SHA1=$(echo "$PACKAGE_NAME" | awk -F- '{print $NF;}')
SUBMODULE=$(basename -- "$PACKAGE_NAME" -"$EXPECTED_SHA1")

cd "$SUBMODULE"

if [ 0 != $(git status --porcelain | wc -l) ]
then
  echo "Submodule has uncommitted changes; aborting" 2>&1
  exit 1
fi

BUILD_PATH=$(mktemp -d)
INSTALL_PATH=$(mktemp -d)
PACKAGE_PATH=$(mktemp -d)
FAKEROOT_STATE=$(mktemp)

function cleanup()
{
  rm -rf "$BUILD_PATH" "$INSTALL_PATH" "$PACKAGE_PATH"
  rm -f "$PACKAGE" "$FAKEROOT_STATE"
}

trap cleanup EXIT

if [ -f configure.ac -o -f configure.in ]
then
  autoreconf -f -i
fi

SHA1=$(git rev-parse HEAD)

if [ "$SHA1" != "$EXPECTED_SHA1" ]
then
  echo "Error: Expected HEAD SHA-1 $EXPECTED_SHA1, found $SHA1" 1>&2
  exit 1
fi

SRC_PATH=$(pwd)

cd "$BUILD_PATH"

if [ -f "$SRC_PATH"/configure ]
then
  "$SRC_PATH"/configure --prefix=/bitraf1 --datarootdir=/bitraf1/share
  make
  fakeroot -s "$FAKEROOT_STATE" -i "$FAKEROOT_STATE" make install DESTDIR="$INSTALL_PATH"
elif [ -f "$SRC_PATH"/Makefile ]
then
  mkdir "$INSTALL_PATH"/bitraf1
  fakeroot -s "$FAKEROOT_STATE" -i "$FAKEROOT_STATE" make -C "$SRC_PATH" install DESTDIR="$INSTALL_PATH"/bitraf1
else
  echo "Warning: No configure script or Makefile found in submodule $SUBMODULE; don't know how to build" 1>&2
  exit 0
fi

cd "$INSTALL_PATH"

fakeroot -i "$FAKEROOT_STATE" zip "$PACKAGE_PATH"/tmp.zip -r bitraf1

mkdir -p "$1"

mv "$PACKAGE_PATH"/tmp.zip "$OUTPUT_PATH"/"$PACKAGE_NAME".zip
