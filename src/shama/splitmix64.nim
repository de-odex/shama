import prelude

type
  SplitMix64* = object
    state: uint64

proc next*(r: var SplitMix64): uint64 =
  r.state += 0x9e3779b97f4a7c15'u64
  var z = r.state
  z = (z xor (z shr 30)) * 0xbf58476d1ce4e5b9'u64
  z = (z xor (z shr 27)) * 0x94d049bb133111eb'u64
  return z xor (z shr 31)

pkgRandomProcGen(SplitMix64, uint64)

proc initSplitMix64*(seed: int64): SplitMix64 = 
  result.state = seed.uint64

