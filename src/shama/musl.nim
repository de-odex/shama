import prelude

type
  MuslRand* = object
    state: uint32

proc temper(x: uint32): uint32 =
  result = x
  result = result xor result shr 11
  result = result xor result shl 7 and 0x9D2C5680
  result = result xor result shl 15 and 0xEFC60000
  result = result xor result shr 18

proc next*(r: var MuslRand): uint64 =
  r.state = r.state * 1103515245 + 12345
  result = temper(r.state)
  r.state = r.state * 1103515245 + 12345
  result = result shl 32 or temper(r.state)

pkgRandomProcGen(MuslRand, uint64)

proc initMuslRand*(seed: int64): MuslRand =
  result.state = seed.uint64

