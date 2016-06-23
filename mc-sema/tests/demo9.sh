#!/bin/bash

source env.sh

rm -f demo_test9.cfg demo_driver9.o demo_test9.o demo_test9_mine.o demo_driver9.exe

${CC} -ggdb -m32 -o demo_test9.o demo_test9.c

#Check if binja is available
python -c 'import binaryninja' 2>>/dev/null
if [ $? == 0 ]
then
    echo "Using Binary Ninja to recover CFG"
    ../bin_descend/get_cfg.py -d demo_test9.o -o demo_test9.cfg -s demo9_map.txt --entry-symbol printit
elif [ -e "${IDA_PATH}/idaq" ]
then
    echo "Using IDA to recover CFG"
    ${BIN_DESCEND_PATH}/bin_descend_wrapper.py -march=x86 -func-map="demo9_map.txt" -entry-symbol=printit -i=demo_test9.o >> /dev/null
else
    echo "Using bin_descend to recover CFG"
    ${BIN_DESCEND_PATH}/bin_descend -march=x86 -d -func-map="demo9_map.txt" -entry-symbol=printit -i=demo_test9.o
fi

${CFG_TO_BC_PATH}/cfg_to_bc -mtriple=i686-pc-linux-gnu -i demo_test9.cfg -driver=demo9_entry,printit,1,return,C -o demo_test9.bc

${LLVM_PATH}/opt -O3 -o demo_test9_opt.bc demo_test9.bc
${LLVM_PATH}/llc -filetype=obj -o demo_test9_mine.o demo_test9_opt.bc
${CC} -ggdb -m32 -o demo_driver9.exe demo_driver9.c demo_test9_mine.o
./demo_driver9.exe
