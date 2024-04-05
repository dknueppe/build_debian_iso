#!/bin/bash

# setup Cache-Way masks for COS 0-4
wrmsr 0xc90 0xe00 # 1110 0000 0000
wrmsr 0xc91 0x1fc # 0001 1100 0000
wrmsr 0xc92 0x038 # 0000 0011 1000
wrmsr 0xc93 0x007 # 0000 0000 0111

# cores 0-2 remain in default COS 0
# is equivalent to the following
#pqos -a 'core:1=3-5'
#pqos -a 'core:2=6'
#pqos -a 'core:3=7'
#
# set core 3-5 to use COS 1
wrmsr -p 3 0xc8f 0x100000000
wrmsr -p 4 0xc8f 0x100000000
wrmsr -p 5 0xc8f 0x100000000
# set core 6 to use COS 2
wrmsr -p 6 0xc8f 0x200000000
# set core 7 to use COS 3
wrmsr -p 7 0xc8f 0x300000000

