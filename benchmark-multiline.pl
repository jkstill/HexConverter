#!/usr/bin/env perl

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use Data::HexConverter;

my $dataFile = 'testdata.hex';

open(my $fh, '<', $dataFile) or die "Could not open file '$dataFile' $!";

my $start_time = [gettimeofday];

my $binaryData;

my $i=0;

while (my $testData = <$fh>) {
	 chomp $testData;
	 $binaryData = Data::HexConverter::hex_to_binary(\$testData);
	 $i++;
}

my $elapsed_time = tv_interval $start_time;

close($fh);

printf "Method: %s\n", hex_to_binary_impl();
printf "Elapsed time: %.4f seconds\n", $elapsed_time;
printf "Average time per conversion: %.6f seconds\n", $elapsed_time / $i;
printf "Size of binary data: %d bytes\n", length($binaryData);

