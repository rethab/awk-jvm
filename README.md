# awk-jvm
a toy jvm in awk, based on this tutorial: https://zserge.com/posts/jvm/

## notes
- this requires gawk, because of functions and the builtin `strtonum`
- you need to specify the -b flag to gawk, or export LC_ALL=C in your shell
  - example (see run.sh): `javac Add.java && cat Add.class  | gawk -bf jvm.awk`
  
# what can it do?
- not a lot (eg. call methods and basic operations, see Add.java)
