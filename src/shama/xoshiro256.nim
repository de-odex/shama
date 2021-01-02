import splitmix64, prelude, xorshiftlike
export Plus, PlusPlus, StarStar, XorshiftLikeGeneratorVariant

type
  Xoshiro256*[G: XorshiftLikeGeneratorVariant] = object
    a0, a1, a2, a3: uint64

template next() {.dirty.} =
  let t = r.a1 shl 17
  r.a2 = r.a2 xor r.a0
  r.a3 = r.a3 xor r.a1
  r.a1 = r.a1 xor r.a2
  r.a0 = r.a0 xor r.a3
  r.a2 = r.a2 xor t
  r.a3 = rotl(r.a3, 45)

proc next*(r: var Xoshiro256[Plus]): uint64 =
  result = r.a0 + r.a3
  next()

proc next*(r: var Xoshiro256[PlusPlus]): uint64 =
  result = rotl(r.a0 + r.a3, 23) + r.a0
  next()

proc next*(r: var Xoshiro256[StarStar]): uint64 =
  result = rotl(r.a1 * 5, 7) * 9
  next()

pkgRandomProcGen(Xoshiro256[XorshiftLikeGeneratorVariant], uint64)

proc initXoshiro256*(seed: int64, G: typedesc[XorshiftLikeGeneratorVariant]): Xoshiro256[G] =
  var sm64 = initSplitMix64(seed)
  result.a0 = sm64.next()
  result.a1 = sm64.next()
  result.a2 = sm64.next()
  result.a3 = sm64.next()

template jump(jumpArr: static array[4, uint64]) {.dirty.} =
  var
    s0 = 0u64
    s1 = 0u64
    s2 = 0u64
    s3 = 0u64
  for i in 0..jumpArr.high:
    for b in 0u64..<64u64:
      if (jumpArr[i] and (1u64 shl b)) != 0:
        s0 = s0 xor r.a0
        s1 = s1 xor r.a1
        s2 = s2 xor r.a2
        s3 = s3 xor r.a3
      discard r.next()
  r.a0 = s0
  r.a1 = s1
  r.a2 = s2
  r.a3 = s3

proc jump*(r: var Xoshiro256[XorshiftLikeGeneratorVariant]) =
  jump([0x180ec6d33cfd0abau64, 0xd5a61266f0c9392cu64, 0xa9582618e03fc9aau64, 0x39abdc4529b1661cu64])

