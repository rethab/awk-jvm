#!/bin/bash

javac Add.java && hexdump -v -e '/1 "%01u "' Add.class  | awk -f jvm.awk
