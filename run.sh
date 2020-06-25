#!/bin/bash

file=$1
if [[ ! -f "$file.java" ]];
then
  echo "$file.java is not a file"
  exit 1
fi

javac "$file.java" && cat "$file.class" | gawk -bf jvm.awk
