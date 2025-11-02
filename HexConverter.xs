#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "src/hexsimd.h"

MODULE = Data::HexConverter   PACKAGE = Data::HexConverter

PROTOTYPES: ENABLE

SV *
hex_to_binary(SV *hex_ref)
CODE:
{
    if (!SvROK(hex_ref)) {
        croak("hex_to_binary: expected a reference to a scalar");
    }

    SV *hex_sv = SvRV(hex_ref);
    STRLEN in_len = 0;
    const char *in = SvPVbyte(hex_sv, in_len);

    if ((in_len & 1) != 0) {
        croak("hex_to_binary: input length must be even");
    }

    SV *out_sv = newSV(in_len / 2);
    SvPOK_on(out_sv);
    char *out_buf = SvGROW(out_sv, (in_len / 2) + 1);

    ptrdiff_t written = hex_to_bytes(in, (size_t)in_len,
                                     (uint8_t *)out_buf,
                                     true);
    if (written < 0) {
        SvREFCNT_dec(out_sv);
        croak("hex_to_binary: hex_to_bytes() failed");
    }

    SvCUR_set(out_sv, (STRLEN)written);
    out_buf[written] = '\0';

    RETVAL = out_sv;
}
OUTPUT:
    RETVAL

SV *
binary_to_hex(SV *bin_ref)
CODE:
{
    if (!SvROK(bin_ref)) {
        croak("binary_to_hex: expected a reference to a scalar");
    }

    SV *bin_sv = SvRV(bin_ref);
    STRLEN in_len = 0;
    const unsigned char *in = (const unsigned char *)SvPVbyte(bin_sv, in_len);

    SV *out_sv = newSV(in_len * 2);
    SvPOK_on(out_sv);
    char *out_buf = SvGROW(out_sv, (in_len * 2) + 1);

    ptrdiff_t written = bytes_to_hex(in, (size_t)in_len, out_buf);
    if (written < 0) {
        SvREFCNT_dec(out_sv);
        croak("binary_to_hex: bytes_to_hex() failed");
    }

    SvCUR_set(out_sv, (STRLEN)written);
    out_buf[written] = '\0';

    RETVAL = out_sv;
}
OUTPUT:
    RETVAL

const char *
hex_to_binary_impl()
CODE:
    RETVAL = hexsimd_hex2bin_impl_name();
OUTPUT:
    RETVAL

const char *
binary_to_hex_impl()
CODE:
    RETVAL = hexsimd_bin2hex_impl_name();
OUTPUT:
    RETVAL
