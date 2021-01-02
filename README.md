# shama
Extra PRNGs for [oprypin/nim-random](https://github.com/oprypin/nim-random)

---

## PRNGs
- SplitMix64
- Xoshiro128(+, ++, **)
- Xoroshiro256(+, ++, **)
- WyRand
- Musl
- PCG (OneSeq, MCG, Unique, SetSeq) (XSH RS, XSH RR, RXS M XS, RXS M, XSL RR, XSL RR RR) (64, 32, 16, 8)
  - no uint128 RNGs here, maybe a TODO

---

## Examples
```nim
import shama/[splitmix64, xoshiro128, xoroshiro256, wyrand, musl, pcg]
import pkg/random/common

# splitmix64, wyrand, and musl
block:
  var r = initSplitMix64(123123123) # or initWyRand, or initMuslRand

# xoshiro128 and xoroshiro256
block:
  var r = initXoshiro128(123123123, Plus) # or PlusPlus, or StarStar

# pcg
block:
  var r = initPcgRand[uint32, Mcg, XshRr](213123)
  #       return type ^~~~~~
  #             state variant ^~~
  #              generator variant ^~~~~
```

## To-do
- standardise init procs to pcg-style instead of xo[ro]shiro-style
