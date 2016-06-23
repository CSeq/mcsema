#!/bin/bash

source env.sh

rm -f demo_test11.cfg demo_driver11.o demo_test11.o demo_test11_mine.o demo_driver11.exe

${CC} -ggdb -m32 -o demo_test11.o demo_test11.c

#Check if binja is available
python -c 'import binaryninja' 2>>/dev/null
if [ $? == 0 ]
then
    echo "Using Binary Ninja to recover CFG"
    ../bin_descend/get_cfg.py -d demo_test11.o -o demo_test11.cfg -s demo11_map.txt --entry-symbol printdata
elif [ -e "${IDA_PATH}/idaq" ]
then
    echo "Using IDA to recover CFG"
    ${BIN_DESCEND_PATH}/bin_descend_wrapper.py -march=x86 -func-map="demo11_map.txt" -entry-symbol=printdata -i=demo_test11.o >> /dev/null
else
    echo "Using bin_descend to recover CFG"
    ${BIN_DESCEND_PATH}/bin_descend -march=x86 -d -func-map="demo11_map.txt" -entry-symbol=printdata -i=demo_test11.o
fi

${CFG_TO_BC_PATH}/cfg_to_bc -mtriple=i686-pc-linux-gnu -i demo_test11.cfg -driver=demo11_entry,printdata,0,return,C -o demo_test11.bc

${LLVM_PATH}/opt -O3 -o demo_test11_opt.bc demo_test11.bc
${LLVM_PATH}/llc -filetype=obj -o demo_test11_mine.o demo_test11_opt.bc
${CC} -ggdb -m32 -o demo_driver11.exe demo_driver11.c demo_test11_mine.o
./demo_driver11.exe
