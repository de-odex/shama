import splitmix64, prelude, xorshiftlike
export Plus, PlusPlus, StarStar, XorshiftLikeGeneratorVariant

type
  Xoroshiro128*[G: XorshiftLikeGeneratorVariant] = object
    a0, a1: uint64

template next(a, b, c: uint64) {.dirty.} =
  let 
    s0 = r.a0
    s1 = r.a1 xor s0
  r.a0 = rotl(s0, a) xor s1 xor (s1 shl b)
  r.a1 = rotl(s1, c)

proc next*(r: var Xoroshiro128[Plus]): uint64 =
  result = r.a0 + r.a1
  next(24, 16, 37)

proc next*(r: var Xoroshiro128[PlusPlus]): uint64 =
  result = rotl(r.a0 + r.a1, 17) + r.a0
  next(49, 21, 28)

proc next*(r: var Xoroshiro128[StarStar]): uint64 =
  result = rotl(r.a0 * 5, 7) * 9
  next(24, 16, 37)

pkgRandomProcGen(Xoroshiro128[XorshiftLikeGeneratorVariant], uint64)

proc initXoroshiro128*(G: typedesc[XorshiftLikeGeneratorVariant], seed: int64): Xoroshiro128[G] =
  var sm64 = initSplitMix64(seed)
  result.a0 = sm64.next()
  result.a1 = sm64.next()

template jump(jumpArr: static array[2, uint64]) {.dirty.} =
  var
    s0 = 0u64
    s1 = 0u64
  for i in 0..jumpArr.high:
    for b in 0u64..<64u64:
      if (jumpArr[i] and (1u64 shl b)) != 0:
        s0 = s0 xor r.a0
        s1 = s1 xor r.a1
      discard r.next()
  r.a0 = s0
  r.a1 = s1

proc jump*(r: var Xoroshiro128[Plus or StarStar]) =
  jump([0xdf900294d8f554a5u64, 0x170865df4b3201fcu64])

proc jump*(r: var Xoroshiro128[PlusPlus]) =
  jump([0x2bd7a6a6e99c2ddcu64, 0x0992ccaf6a6fca05u64])

