#!/bin/bash

file=$1
if [[ ! -f "$file.java" ]];
then
  echo "$file.java is not a file"
  exit 1
fi

javac "$file.java" && hexdump -v -e '/1 "%01u "' "$file.class"  | awk -f jvm.awk
