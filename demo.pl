
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

