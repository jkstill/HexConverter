#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <tmmintrin.h>
#include <stdlib.h>

/*
 * This XS module exposes a single function, hex_to_binary(), which
 * converts an even‑length ASCII hex string into a binary octet
 * sequence.  The implementation below is adapted from an OCI‑based
 * function and rewritten to operate on plain C data.  It uses the
 * SSSE3 intrinsics _mm_shuffle_epi8() and friends to process 32
 * characters at a time.  Remaining bytes are handled with a
 * lookup table.  Before any conversions occur the lookup table is
 * initialised in BOOT: using init_hex_lookup_table().
 */

static unsigned char hex_lookup[256];
static int hex_lookup_initialised = 0;

static void
init_hex_lookup_table(void)
{
    for (int i = 0; i < 256; i++)
        hex_lookup[i] = 0xFF;
    for (int i = '0'; i <= '9'; i++)
        hex_lookup[i] = (unsigned char)(i - '0');
    for (int i = 'A'; i <= 'F'; i++)
        hex_lookup[i] = (unsigned char)(i - 'A' + 10);
    for (int i = 'a'; i <= 'f'; i++)
        hex_lookup[i] = (unsigned char)(i - 'a' + 10);
    hex_lookup_initialised = 1;
}

static int
hex_to_binary_ssse3(const unsigned char *hex_data, size_t n,
                    unsigned char *binary_out, char **err_msg)
{
    size_t i;
    for (i = 0; i + 32 <= n; i += 32) {
        __m128i block1 = _mm_loadu_si128((const __m128i *)(hex_data + i));
        __m128i block2 = _mm_loadu_si128((const __m128i *)(hex_data + i + 16));
        __m128i idxEven = _mm_setr_epi8(
            0,  2,  4,  6,  8, 10, 12, 14,
            (char)0x80,(char)0x80,(char)0x80,(char)0x80,
            (char)0x80,(char)0x80,(char)0x80,(char)0x80
        );
        __m128i idxOdd = _mm_setr_epi8(
            1,  3,  5,  7,  9, 11, 13, 15,
            (char)0x80,(char)0x80,(char)0x80,(char)0x80,
            (char)0x80,(char)0x80,(char)0x80,(char)0x80
        );
        __m128i evens_block1 = _mm_shuffle_epi8(block1, idxEven);
        __m128i odds_block1  = _mm_shuffle_epi8(block1, idxOdd);
        __m128i evens_block2 = _mm_shuffle_epi8(block2, idxEven);
        __m128i odds_block2  = _mm_shuffle_epi8(block2, idxOdd);
        __m128i evens = _mm_or_si128(evens_block1,
                                     _mm_slli_si128(evens_block2, 8));
        __m128i odds  = _mm_or_si128(odds_block1,
                                     _mm_slli_si128(odds_block2,  8));
        __m128i zero = _mm_set1_epi8('0');
        evens = _mm_sub_epi8(evens, zero);
        odds  = _mm_sub_epi8(odds,  zero);
        __m128i chars_evens = _mm_add_epi8(evens, zero);
        __m128i chars_odds  = _mm_add_epi8(odds,  zero);
        __m128i upperA = _mm_set1_epi8('A' - 1);
        __m128i upperF = _mm_set1_epi8('F' + 1);
        __m128i lowerA = _mm_set1_epi8('a' - 1);
        __m128i lowerF = _mm_set1_epi8('f' + 1);
        __m128i ucase_mask_e = _mm_and_si128(_mm_cmpgt_epi8(chars_evens, upperA),
                                             _mm_cmplt_epi8(chars_evens, upperF));
        __m128i lcase_mask_e = _mm_and_si128(_mm_cmpgt_epi8(chars_evens, lowerA),
                                             _mm_cmplt_epi8(chars_evens, lowerF));
        __m128i ucase_mask_o = _mm_and_si128(_mm_cmpgt_epi8(chars_odds,  upperA),
                                             _mm_cmplt_epi8(chars_odds,  upperF));
        __m128i lcase_mask_o = _mm_and_si128(_mm_cmpgt_epi8(chars_odds,  lowerA),
                                             _mm_cmplt_epi8(chars_odds,  lowerF));
        evens = _mm_sub_epi8(evens,
                             _mm_and_si128(ucase_mask_e,
                                           _mm_set1_epi8(7)));
        odds  = _mm_sub_epi8(odds,
                             _mm_and_si128(ucase_mask_o,
                                           _mm_set1_epi8(7)));
        evens = _mm_sub_epi8(evens,
                             _mm_and_si128(lcase_mask_e,
                                           _mm_set1_epi8(39)));
        odds  = _mm_sub_epi8(odds,
                             _mm_and_si128(lcase_mask_o,
                                           _mm_set1_epi8(39)));
        __m128i high_shifted = _mm_slli_epi16(evens, 4);
        __m128i bytes = _mm_or_si128(high_shifted, odds);
        _mm_storeu_si128((__m128i *)(binary_out + i/2), bytes);
    }
    for (; i < n; i += 2) {
        unsigned char high = hex_lookup[hex_data[i]];
        unsigned char low  = hex_lookup[hex_data[i + 1]];
        if (high == 0xFF || low == 0xFF) {
            if (err_msg) {
                *err_msg = "Invalid hex digit";
            }
            return -1;
        }
        binary_out[i / 2] = (high << 4) | low;
    }
    return 0;
}

MODULE = Oracle::XS::HexConverter   PACKAGE = Oracle::XS::HexConverter

BOOT:
    if (!hex_lookup_initialised) {
        init_hex_lookup_table();
    }

SV*
hex_to_binary(SV* hex_ref)
    PREINIT:
        SV    *sv_hex;
        STRLEN hex_len;
        unsigned char *hex_str;
        unsigned char *binary_out;
        char  *err_msg = NULL;
        int    rc;
    PPCODE:
        if (!SvROK(hex_ref)) {
            croak("Argument must be a reference to a scalar containing a hex string");
        }
        sv_hex = SvRV(hex_ref);
        SvGETMAGIC(sv_hex);
        if (SvUTF8(sv_hex) && !sv_utf8_downgrade(sv_hex, TRUE)) {
            croak("Input string must contain only ASCII characters and be downgradeable");
        }
        hex_str = (unsigned char *)SvPVbyte(sv_hex, hex_len);
        if (hex_len == 0) {
            XPUSHs(sv_2mortal(newSVpvs("")));
            XSRETURN(1);
        }
        if ((hex_len & 1) != 0) {
            croak("Hex string length must be even");
        }
        binary_out = (unsigned char *)malloc(hex_len / 2);
        if (!binary_out) {
            croak("Memory allocation failed");
        }
        rc = hex_to_binary_ssse3(hex_str, (size_t)hex_len, binary_out, &err_msg);
        if (rc != 0) {
            free(binary_out);
            croak("%s", err_msg);
        }
        SV *result = newSVpvn((const char *)binary_out, hex_len/2);
        free(binary_out);
        XPUSHs(sv_2mortal(result));
        XSRETURN(1);