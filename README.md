# awk-jvm
a toy jvm in awk, based on this tutorial: https://zserge.com/posts/jvm/

## notes
- this requires gawk, because of functions and the builtin `strtonum`
- since none of the awks can read binary, you first need to pipe the classfile through hexdump
  - example (see run.sh): `javac Add.java && hexdump -v -e '/1 "%01u "' Add.class  | awk -f jvm.awk`
  
# what can it do?
- not a lot (eg. call methods and basic operations, see Add.java)
