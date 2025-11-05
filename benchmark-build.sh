#!/usr/bin/env bash

make clean
#HEXSIMD_HAVE_AVX512=1 make -f make-dist.mk clean
#HEXSIMD_HAVE_AVX512=1 make -f make-dist.mk src/hexsimd.o
make -f make-dist.mk clean
make -f make-dist.mk src/hexsimd.o

#exit

#HEXSIMD_HAVE_AVX512=1 gcc    -O3 -DHEXSIMD_HAVE_AVX512=1 -Wall -Wextra -mno-avx512f -mavx512bw -mavx512vl -L ./src -l:hexsimd.o -o benchmark benchmark.c

#HEXSIMD_HAVE_AVX512=1  gcc -g -O3 -DHEXSIMD_ENABLE_AVX512 -Wall -Wextra -mno-avx512f -mavx512bw -mavx512vl  src/hexsimd.o -o benchmark benchmark.c
gcc -g -O3 -Wall -Wextra src/hexsimd.o -o benchmark benchmark.c
gcc -g -O3 -Wall -Wextra src/hexsimd.o -o benchmark-multiline benchmark-multiline.c 

[[ -f ./testdata.hex ]] || ./create-random-testdata.sh

#export DEBUG_IMPL=1 HEXSIMD_FORCE=avx512 
./benchmark testdata.txt
./benchmark-multiline testdata.hex

