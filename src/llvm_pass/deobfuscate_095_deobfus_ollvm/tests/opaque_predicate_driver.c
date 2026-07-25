#include <stdint.h>
#include <stdio.h>

#define DECL1(name, type) extern int32_t name(type)
#define DECL0(name) extern int32_t name(void)

DECL1(setz_self, int32_t);
DECL1(setnz_self, int32_t);
DECL1(setb_self, int32_t);
DECL1(setae_self, int32_t);
DECL1(seta_self, int32_t);
DECL1(setbe_self, int32_t);
DECL1(setl_self, int32_t);
DECL1(setge_self, int32_t);
DECL1(setg_self, int32_t);
DECL1(setle_self, int32_t);
DECL1(setz_and_complement, int32_t);
DECL1(setnz_or_complement, int32_t);
DECL1(setz_xor_self, int32_t);
DECL1(setnz_xor_self, int32_t);
DECL1(setnz_or_one, int32_t);
DECL1(setz_and_zero, int32_t);
DECL1(setnz_or_minus_one, int32_t);
DECL1(setb_zero, int32_t);
DECL1(setae_zero, int32_t);
DECL0(set_const);
DECL0(lnot_one);
DECL0(lnot_zero);
DECL1(lnot_lnot, int32_t);
DECL1(set_rule_z3, int32_t);
DECL1(negative_width_cast, int8_t);
DECL1(negative_signed_or_odd, int32_t);

int main(void) {
  int32_t x = (int32_t)0x81234567u;
  printf("%d%d%d%d%d%d%d%d%d%d\n",
         setz_self(x), setnz_self(x), setb_self(x), setae_self(x),
         seta_self(x), setbe_self(x), setl_self(x), setge_self(x),
         setg_self(x), setle_self(x));
  printf("%d%d%d%d%d%d%d%d%d\n",
         setz_and_complement(x), setnz_or_complement(x), setz_xor_self(x),
         setnz_xor_self(x), setnz_or_one(x), setz_and_zero(x),
         setnz_or_minus_one(x), setb_zero(x), setae_zero(x));
  printf("%d%d%d %d%d %d%d %d%d\n",
         set_const(), lnot_one(), lnot_zero(),
         lnot_lnot(9), lnot_lnot(10),
         set_rule_z3(x), set_rule_z3(0),
         negative_width_cast((int8_t)0x7f),
         negative_width_cast((int8_t)0x80));
  printf("%d%d\n", negative_signed_or_odd(0),
         negative_signed_or_odd(-1));
  return 0;
}
