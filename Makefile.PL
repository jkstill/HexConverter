use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Oracle::XS::HexConverter',
    VERSION_FROM => 'Oracle/XS/HexConverter.pm',
    LIBS         => [''],     # e.g., '-lm'
    DEFINE       => '-mssse3',# pass the SSSE3 flag to the compiler
    INC          => '',       # e.g., '-I/usr/include/other'
    # Let MakeMaker know where our tests live.  Any .t files in the
    # t/ directory will be executed when you run 'make test'.  This
    # overrides the default wildcard if you need a custom pattern.
);
