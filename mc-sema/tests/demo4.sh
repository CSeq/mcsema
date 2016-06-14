#!/bin/bash

source env.sh

rm -f demo_test4.cfg demo_driver4.o demo_test4.o demo_test4_mine.o demo_driver4.exe

${CC} -ggdb -m32 -o demo_test4.o demo_test4.c

#Check if binja is available
python -c 'import binaryninja' 2>>/dev/null
if [ $? == 0 ]
then
    echo "Using Binary Ninja to recover CFG"
    ../bin_descend/get_cfg.py -d demo_test4.o -o demo_test4.cfg -s demo4_map.txt --entry-symbol doTrans
elif [ -e "${IDA_PATH}/idaq" ]
then
    echo "Using IDA to recover CFG"
    ${BIN_DESCEND_PATH}/bin_descend_wrapper.py -march=x86 -func-map="demo4_map.txt" -entry-symbol=doTrans -i=demo_test4.o >> /dev/null
else
    echo "Using bin_descend to recover CFG"
    ${BIN_DESCEND_PATH}/bin_descend -march=x86 -d -func-map="demo4_map.txt" -entry-symbol=doTrans -i=demo_test4.o
fi

${CFG_TO_BC_PATH}/cfg_to_bc -mtriple=i686-pc-linux-gnu -i demo_test4.cfg -driver=demo4_entry,doTrans,1,return,C -o demo_test4.bc

${LLVM_PATH}/opt -O3 -o demo_test4_opt.bc demo_test4.bc
${LLVM_PATH}/llc -filetype=obj -o demo_test4_mine.o demo_test4_opt.bc
${CC} -ggdb -m32 -o demo_driver4.exe demo_driver4.c demo_test4_mine.o
./demo_driver4.exe
