#!/bin/sh
ROOT="`pwd`"
DIR=./erts-%%ERTS_VSN%%/bin
sed s:%FINAL_ROOTDIR%:\""${ROOT}"\": $DIR/erl.src > $DIR/erl.tmp
sed s:\$BINDIR:\"\$BINDIR\": $DIR/erl.tmp > $DIR/erl
rm $DIR/erl.tmp
