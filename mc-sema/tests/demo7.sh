#!/bin/bash

source env.sh

rm -f demo_test7.cfg demo_driver7.o demo_test7.o demo_test7_mine.o demo_driver7.exe

${CC} -ggdb -m32 -o demo_test7.o demo_test7.c

#Check if binja is available
python -c 'import binaryninja' 2>>/dev/null
if [ $? == 0 ]
then
    echo "Using Binary Ninja to recover CFG"
    ../bin_descend/get_cfg.py -d demo_test7.o -o demo_test7.cfg -s demo7_map.txt --entry-symbol checkFn
elif [ -e "${IDA_PATH}/idaq" ]
then
    echo "Using IDA to recover CFG"
    ${BIN_DESCEND_PATH}/bin_descend_wrapper.py -march=x86 -func-map="demo7_map.txt" -entry-symbol=checkFn -i=demo_test7.o >> /dev/null
else
    echo "Using bin_descend to recover CFG"
    ${BIN_DESCEND_PATH}/bin_descend -march=x86 -d -func-map="demo7_map.txt" -entry-symbol=checkFn -i=demo_test7.o
fi

${CFG_TO_BC_PATH}/cfg_to_bc -mtriple=i686-pc-linux-gnu -i demo_test7.cfg -driver=demo7_entry,checkFn,1,return,C -o demo_test7.bc

${LLVM_PATH}/opt -O3 -o demo_test7_opt.bc demo_test7.bc
${LLVM_PATH}/llc -filetype=obj -o demo_test7_mine.o demo_test7_opt.bc
${CC} -ggdb -m32 -o demo_driver7.exe demo_driver7.c demo_test7_mine.o
./demo_driver7.exe
