#!/bin/bash

if [ $# -ne 1 ]
then
  echo "Usage: $0 <PACKAGE>" 1>&2
  exit 1
fi

unzip "$1" bitraf1/* -d /
