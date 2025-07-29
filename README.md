

# Data-HexConverter

There are many ways to convert between binary and hex, but this module was created for specific purpose:

To convert binary data to hex, and then back to binary, while preserving the original binary data.

And do so as quickly as possible.

Currently on a VM where this module is tested, a 2M object encoded as a hex string is converted to binary in about 220 microseconds.

The `pack()` function was previously used for this, but  it is no nearly as fast as this module.

Data::HexConverter is about 36x faster than `pack()` for this purpose.


## Installation

To install this module, run the following commands:

```text
	perl Makefile.PL
	make
	make test
	make install
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

### Example 1: Converting Binary to Hex

```perl

use strict;
use warnings;
use Test::More;

use Data::HexConverter qw(binary_to_hex);

my $bin = "Hello";
my $hex = Data::HexConverter::binary_to_hex(\$bin);

$bin = "JKL";
$hex = Data::HexConverter::binary_to_hex(\$bin);

$bin = pack("C*", 0x00, 0xFF, 0x7F, 0x80);
$hex = Data::HexConverter::binary_to_hex(\$bin);

```

### Example 2: Converting Hex to Binary

```perl

use strict;
use warnings;
use Data::HexConverter qw(hex_to_binary);

my $hex = "48656c6c6f";       # "Hello" in hex
my $bin = hex_to_binary(\$hex);

$hex = "4a4B4c";            # mixed case: "JKL"
$bin = hex_to_binary(\$hex);
```

