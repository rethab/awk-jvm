#!/bin/bash

file=$1
if [[ ! -f "${file}.java" ]];
then
  echo "${file}.java not found"
  exit 1
fi

javac "${file}.java" && gawk -bf jvm.awk "${file}.class"
