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
  var r = initXoshiro128(Plus, 123123123) # or PlusPlus, or StarStar

# pcg
block:
  var r = initPcgRand(Mcg, XshRr, 123123123)
  #     state variant ^~~
  #      generator variant ^~~~~
  #                          seed ^~~~~~~~~
  # (careful, return type is dependent on seed type)
  #[
    State Variants:
      OneSeq
      Mcg
      Unique
      SetSeq
    Generator Variants:
      XshRs
      XshRr
      RxsMXs
      RxsM
      XslRr
      XslRrRr
  ]#
```

## To-do
- make pcg return types easier to deal with
