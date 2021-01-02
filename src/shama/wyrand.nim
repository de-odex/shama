
# wyrand has awful code in terms of readability.

type
  WyRand* = object
    a0: uint64

const
  condom = 1

proc rot(x: uint64): uint64 =
  result = x shr 32 or x shl 32

proc mum(a: var uint64, b: var uint64) =
  when sizeof int == 4:
    var 
      hh = uint64((a shr 32) * (b shr 32))
      hl = uint64((a shr 32) * uint32(b))
      lh = uint64(uint32(a) * (b shr 32))
      ll = uint64(uint32(a) * uint32(b))
    when condom > 1:
      a = a xor rot(hl) xor hh 
      B = b xor rot(lh) xor ll
    else:
      a = rot(hl) xor hh
      b = rot(lh) xor ll
  else:
    let
      ha = a shr 32
      hb = b shr 32
      la = a.uint32.uint64
      lb = b.uint32.uint64
      rh = ha * hb
      rm0 = ha * lb
      rm1 = hb * la
      rl = la * lb
      t = rl + (rm0 shl 32)
    var
      hi: uint64
      lo: uint64
      c = uint64 t<rl
    lo = t + (rm1 shl 32)
    c += uint64 lo<t
    hi = rh + (rm0 shr 32) + (rm1 shr 32) + c

    when condom > 1:
      a = a xor lo
      b = b xor hi
    else:
      a = lo
      b = hi

proc mix(a, b: uint64): uint64 = 
  var (a2, b2) = (a, b)
  mum(a2, b2)
  result = a2 xor b2

const p = [0xa0761d6478bd642f'u64, 0xe7037ed1a0b428db'u64, 0x8ebc6af09c88c6e3'u64, 0x589965cc75374cc3'u64, 0x1d8e4e27c47d124f'u64]

proc next*(r: var WyRand): uint64 =
  {.push overflowChecks: off.}
  r.state += p[0]
  {.pop.}
  result = mix(r.state, r.state xor p[1])

pkgRandomProcGen(WyRand, uint64)

proc initWyRand*(seed: int64): WyRand =
  result.state = seed.uint64

