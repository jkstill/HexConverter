

# Data-HexConverter

There are many ways to convert between binary and hex, but this module was created for specific purpose:

To convert binary data to hex, and then back to binary, while preserving the original binary data.

And do so as quickly as possible.

Currently on a VM where this module is tested, a 2M object encoded as a hex string is converted to binary in about 220 microseconds.

The `pack()` function was previously used for this, but  it is no nearly as fast as this module.

Data::HexConverter is about 36x faster than `pack()` for this purpose.


## CPU Features

Determine if you CPU supports AVX 512 instructions:

On a local VM:

```bash
  $ gcc -O3 -Wall -Wextra -mavx512bw -mavx512vl -o probe_isa probe_isa.c

  $  ./probe_isa
  FEATURES: sse2 avx avx2
```

On a local server that supports AVX 512:

```bash
  $ gcc -O3 -Wall -Wextra -mavx512bw -mavx512vl -o probe_isa probe_isa.c

  $ ./probe_isa
  FEATURES: sse2 avx avx2 avx512bw avx512vl
```

## Installation

To install this module, run the following commands:

AVX 512 are automatically enabled if supported by the CPU.

```text
	perl Makefile.PL
	make
	make test
	make install
```

## Verify Implementation Used

Local VM without AVX 512:

```bash
  $  PERL5LIB=./lib LD_LIBRARY_PATH=$LD_LIBRARY_PATH:./blib/arch/auto/Data/HexConverter perl isa.pl
  Hex to Binary Implementation:
  avx2
  Binary to Hex Implementation:
  avx2
```

Local Server with AVX 512:

```bash
  $  PERL5LIB=./lib LD_LIBRARY_PATH=$LD_LIBRARY_PATH:./blib/arch/auto/Data/HexConverter perl isa.pl
  Hex to Binary Implementation:
  avx512bw
  Binary to Hex Implementation:
  avx512bw
```

## C Demo Programs

The `demo` program can be created from the hexsimd.c source code.

```bash
    $ make -f make-dist.mk demo
    $ ./demo
```

The program `demo-2` can created via gcc:

```bash
    $ gcc -O3 -Wall -Wextra -mavx512bw -mavx512vl -L ./src -l:hexsimd.o -o demo-2 demo-2.c
    $ ./demo-2
```

## Benchmarking Demo Programs

There are some basic benchmarking demo programs available

### C

Run the script `benchmark-build.sh` to build and run the C benchmark programs.

The first time it runs it will build the benchmark programs and a data files `testdat.hex`, which is ~ 2GGB in size.

```bash
$  ./benchmark-build.sh
make: *** No rule to make target 'clean'.  Stop.
rm -f src/*.o libhexsimd.so* demo demo-2
cc -O3 -Wall -Wextra -fPIC -fvisibility=hidden -march=x86-64 -mno-avx -mno-avx2 -DHEXSIMD_BUILD -c src/hexsimd.c -o src/hexsimd.o

Creating testdata...

Added 964037 bytes to testdata.hex
Added 1870469 bytes to testdata.hex
Added 1083589 bytes to testdata.hex
...

Running benchmarks...

Single-line benchmark:

ISA: sse2=1 avx=1 avx2=1 avx512bw=0 avx512vl=0
file size: 2097153 bytes, bytes read: 2097153
avx2
OK
optimized lookup avx2 took 0.129217 seconds for 1000 tests, avg: 0.000129217
g_hex2bin_name: avx2

Multi-line benchmark:

ISA: sse2=1 avx=1 avx2=1 avx512bw=0 avx512vl=0
g_hex2bin_name: avx2
Processed 1000 lines from testdata.hex
Total hex->bin time: 0.137120 seconds
Average per line: 0.000137120 seconds
```

### Perl

It is assumed that `testdat.hex` has already been created by running the C benchmark build script.

Single-line benchmark:

```bash
$  perl benchmark.pl
Method: avx2
Elapsed time: 0.1704 seconds
Average time per conversion: 0.000170 seconds
Size of binary data: 1048576 bytes
```

Multi-line benchmark:

```bash
$  perl benchmark-multiline.pl
Method: avx2
Elapsed time: 0.5894 seconds
Average time per conversion: 0.000589 seconds
Size of binary data: 2042629 bytes
```

## Support and Documentation

After installing, you can find documentation for this module with the perldoc command.

   `perldoc Data::HexConverter`

You can also look for information at:

    [RT, CPAN's request tracker (report bugs here)]
        (https://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-HexConverter)

    [CPAN Ratings]
        (https://cpanratings.perl.org/d/Data-HexConverter)

    [Search CPAN]
        (https://metacpan.org/release/Data-HexConverter)


## Usage

Following are some examples of how to use this module.

These are simple examples, taken directly from the test code.

These can be used to encode and decode much larger objects.

### Converting Binary to Hex and Back to Hex

demo.pl:

```perl
use strict;
use warnings;

use Data::HexConverter;

print "\nVersion: ", $Data::HexConverter::VERSION, "\n";

my $hexToBinImplementation   = hex_to_binary_impl();
my $binToHexImplementation   = binary_to_hex_impl();

print "Hex to Binary Implementation:\n$hexToBinImplementation\n";
print "Binary to Hex Implementation:\n$binToHexImplementation\n";

my ($hex,$back,$data);

$data = "Hello";
print "\nData: $data\n";
$hex = binary_to_hex(\$data);
print "Hex: $hex\n";
$back = hex_to_binary(\$hex);
print "Back to Data: $back\n";

$data = "JKL";
print "\nData: $data\n";
$hex = binary_to_hex(\$data);
print "Hex: $hex\n";
$back = hex_to_binary(\$hex);
print "Back to Data: $back\n";

$data = pack("C*", 0x00, 0xFF, 0x7F, 0x80);
print "\nData: Binary data (non-printable)\n";
$hex = binary_to_hex(\$data);
print "Hex: $hex\n";
$back = hex_to_binary(\$hex);
print "Back to Data: unprintable binary data\n";

```

Run demo.pl:

```bash
$  PERL5LIB=./lib LD_LIBRARY_PATH=$LD_LIBRARY_PATH:./blib/arch/auto/Data/HexConverter perl demo.pl

Version: 0.5
Hex to Binary Implementation:
avx2
Binary to Hex Implementation:
avx2

Data: Hello
Hex: 48656C6C6F
Back to Data: Hello

Data: JKL
Hex: 4A4B4C
Back to Data: JKL

Data: Binary data (non-printable)
Hex: 00FF7F80
Back to Data: unprintable binary data

```

## Benchmark

AVX2 Implementation on a local VM:

```text
$ perl benchmark.pl tesdata.txt
Method: avx2
Elapsed time: 0.1683 seconds
Average time per conversion: 0.000168 seconds
Size of binary data: 1048576 bytes
```

AVX512 Implementation on a local server:

```text
$ perl benchmark.pl tesdata.txt
Method: avx512bw
Elapsed time: 0.0945 seconds
Average time per conversion: 0.000094 seconds
Size of binary data: 1048576 bytes
```


