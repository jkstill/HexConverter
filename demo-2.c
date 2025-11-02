
// gcc -O3 -Wall -Wextra -mavx512bw -mavx512vl -L ./src -l:hexsimd.o -o demo-2 demo-2.c

#include "hexsimd.h"
#include <stdlib.h>   // getenv
#include <strings.h>  // strcasecmp (or use strcmp if you prefer exact case)
#include <string.h>  // for memcpy
#include <stdio.h>
#include <stdint.h>

#if defined(_MSC_VER)
  #include <intrin.h>
#else
  #include <immintrin.h>
#endif

/* decide once. at compile time. whether AVX512 code exists in this file */
#if (defined(__AVX512BW__) && defined(__AVX512VL__)) || defined(HEXSIMD_ENABLE_AVX512)
#  define HEXSIMD_HAVE_AVX512 1
#else
#  define HEXSIMD_HAVE_AVX512 0
#endif

// -------------------------
// CPUID / XGETBV helpers
// -------------------------
static void cpuid_x86(unsigned leaf, unsigned subleaf, unsigned regs[4]) {
#if defined(_MSC_VER)
    int cpuInfo[4];
    __cpuidex(cpuInfo, (int)leaf, (int)subleaf);
    regs[0]=(unsigned)cpuInfo[0]; regs[1]=(unsigned)cpuInfo[1];
    regs[2]=(unsigned)cpuInfo[2]; regs[3]=(unsigned)cpuInfo[3];
#else
    unsigned a,b,c,d;
    __asm__ volatile("cpuid" : "=a"(a), "=b"(b), "=c"(c), "=d"(d)
                               : "a"(leaf), "c"(subleaf));
    regs[0]=a; regs[1]=b; regs[2]=c; regs[3]=d;
#endif
}

static unsigned long long xgetbv_x86(unsigned idx) {
#if defined(_MSC_VER)
    return _xgetbv(idx);
#else
    unsigned eax, edx;
    __asm__ volatile (".byte 0x0f, 0x01, 0xd0" : "=a"(eax), "=d"(edx) : "c"(idx));
    return ((unsigned long long)edx << 32) | eax;
#endif
}

typedef struct {
    int sse2, avx, avx2, avx512bw, avx512vl;
} isa_t;

static isa_t detect_isa_runtime(void) {
    isa_t f = {0};
    unsigned r[4] = {0};
    cpuid_x86(1,0,r);
    int osxsave = (r[2] & (1u<<27)) != 0;
    f.sse2 = (r[3] & (1u<<26)) != 0;

    if (osxsave) {
        unsigned long long xcr0 = xgetbv_x86(0);
        int os_avx = ((xcr0 & 0x6) == 0x6);
        if (os_avx && (r[2] & (1u<<28))) f.avx = 1;

        cpuid_x86(7,0,r);
        if (f.avx) f.avx2 = (r[1] & (1u<<5)) != 0;

        int os_avx512 = ((xcr0 & 0xE0) == 0xE0);
        if (os_avx512) {
            f.avx512bw = (r[1] & (1u<<30)) != 0;
            f.avx512vl = (r[1] & (1u<<31)) != 0;
        }
    }
    return f;
}

//
// -------------------------
// Optional micro-test
// -------------------------
extern const char* hexsimd_hex2bin_impl_name(void);

static void dump_features(void){
    isa_t f = detect_isa_runtime();
    printf("ISA: sse2=%d avx=%d avx2=%d avx512bw=%d avx512vl=%d\n",
           f.sse2, f.avx, f.avx2, f.avx512bw, f.avx512vl);
}


int main(void){
    dump_features(); 
    char *hx = "32D45FA2883337F16CAF523264E538D1AD89BD2924B67693AF1A7BCE7C6041AC96528A702C1FCAB51F75B14B6A5F20B1BAAFD93E9AC30769247EB6FAF408087F38E4BFB318CFA3A38FBA7206081ECEB9E7C4BC25201A14D5BCC6A6590B96A4738C9BCE941C541D688C8195550F6EF9CEEDD06353FB7A033AF63B40701632049C";
    size_t BIN_LEN = strlen(hx)+1;
    uint8_t *bin = malloc(BIN_LEN);
    char *back = malloc( (BIN_LEN * 2) +1);
    memset(back, 0x5A, BIN_LEN * 2);
		   
    ptrdiff_t n = hex_to_bytes(hx, strlen(hx), bin, true);
    if (n < 0) { puts("parse failed"); return 1; }
    ptrdiff_t m = bytes_to_hex(bin, (size_t)n, back);
    back[m] = 0;
    puts(hexsimd_hex2bin_impl_name());

    int match = strcmp(hx,back);

    if (match == 0 ){
        puts(back);
    } else {
	printf("match: %d\n", match);
        printf("Source: %s\n",hx);
        printf("  Dest: %s\n",back);
        printf("Error! Src and Dest do not match\n");
	return 1;
    }

    return 0;
}


