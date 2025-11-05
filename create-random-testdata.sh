#!/usr/bin/env bash

# This script generates random test hex data files for testing purposes.

dataFile="testdata.hex"
> $dataFile

for i in {1..1000}; do
	size=$(((RANDOM * 64) + 517))
	xxd -c 0 -l $size -ps /dev/urandom | tr '[a-z]' '[A-Z]' >> $dataFile
	echo "Added $size bytes to $dataFile"
done

