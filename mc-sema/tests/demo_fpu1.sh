#!/bin/bash

source env.sh

rm -f demo_fpu1.cfg demo_driver_fpu1.o demo_fpu1.o demo_fpu1_mine.o demo_driver_fpu1.exe

${CC} -ggdb -m32 -o demo_fpu1.o demo_fpu1.c

#Check if binja is available
python -c 'import binaryninja' 2>>/dev/null
if [ $? == 0 ]
then
    echo "Using Binary Ninja to recover CFG"
    ../bin_descend/get_cfg.py -d demo_fpu1.o -o demo_fpu1.cfg --entry-symbol timespi
elif [ -e "${IDA_PATH}/idaq" ]
then
    echo "Using IDA to recover CFG"
    ${BIN_DESCEND_PATH}/bin_descend_wrapper.py -march=x86 -d -entry-symbol=timespi -i=demo_fpu1.o>> /dev/null
else
    echo "Using bin_descend to recover CFG"
    ${BIN_DESCEND_PATH}/bin_descend -d -march=x86 -entry-symbol=timespi -i=demo_fpu1.o
fi

${CFG_TO_BC_PATH}/cfg_to_bc -mtriple=i686-pc-linux-gnu -i demo_fpu1.cfg -driver=demo_fpu1_entry,timespi,raw,return,C -o demo_fpu1.bc

${LLVM_PATH}/opt -O3 -o demo_fpu1_opt.bc demo_fpu1.bc
${LLVM_PATH}/llc -filetype=obj -o demo_fpu1_mine.o demo_fpu1_opt.bc
${CC} -ggdb -m32 -o demo_driver_fpu1.exe demo_driver_fpu1.c demo_fpu1_mine.o
./demo_driver_fpu1.exe
