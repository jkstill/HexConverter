use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Data::HexConverter',
    VERSION_FROM => 'Data/HexConverter.pm',
    LIBS         => [''],     # e.g., '-lm'
    DEFINE       => '-mssse3',# pass the SSSE3 flag to the compiler
    INC          => '',       # e.g., '-I/usr/include/other'
    PM => {
        'Data/HexConverter.pm' => '$(INST_LIB)/Data/HexConverter.pm',
    },
);
