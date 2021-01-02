import macros, parseutils, strutils

macro smaller(t: typedesc): typedesc = 
  var index: int
  var name: string
  var num: int
  index = ($t).parseUntil(name, Digits, index)
  index = ($t).parseInt(num, index)
  num = num div 2
  result = ident(name & $num)

macro bigger(t: typedesc): typedesc = 
  var index: int
  var name: string
  var num: int
  index = ($t).parseUntil(name, Digits, index)
  index = ($t).parseInt(num, index)
  num = num * 2
  result = ident(name & $num)

proc rotr[T: SomeUnsignedInt](value: T, rot: SomeInteger): T =
  result = (value shr rot) or (value shl ((-(rot.int64)) and sizeof(T)*8-1))

import prelude

type
  # distinct objects always feel very different from just copying objects
  PcgRand[T: SomeUnsignedInt, S: PcgStateVariant, G: PcgGeneratorVariant] = object
    state: T
    when S is SetSeq:
      incr: uint64

  # state variants
  OneSeq = distinct void
  Mcg = distinct void
  Unique = distinct void
  SetSeq = distinct void
  PcgStateVariant = OneSeq or Mcg or Unique or SetSeq

  # generator variants
  XshRs = distinct void
  XshRr = distinct void
  RxsMXs = distinct void
  RxsM = distinct void
  XslRr = distinct void
  XslRrRr = distinct void
  PcgGeneratorVariant = XshRs or XshRr or RxsMXs or RxsM or XslRr or XslRrRr
  PcgSmallerReturnGenerator = XshRs or XshRr or RxsM or XslRr
  PcgEqualReturnGenerator = RxsMXs or XslRrRr

# --- output
# xsh rs
template outputXshRs(stateTyp: typedesc, consts: varargs[uint32]) =
  proc output[S: PcgStateVariant](r: PcgRand[stateTyp, S, XshRs]): smaller(stateTyp) =
    result = smaller(stateTyp)(((r.state shr consts[0]) or r.state) shr ((r.state shr consts[1]) + consts[2]))
outputXshRs(uint16, 7, 14, 3)
outputXshRs(uint32, 11, 30, 11)
outputXshRs(uint64, 22, 61, 22)

# xsh rr
template outputXshRr(stateTyp: typedesc, consts: varargs[uint32]) =
  proc output[S: PcgStateVariant](r: PcgRand[stateTyp, S, XshRr]): smaller(stateTyp) =
    result = rotr(smaller(stateTyp)(((r.state shr consts[0]) xor r.state) shr consts[1]), r.state shr consts[2])
outputXshRr(uint16, 5, 5, 13)
outputXshRr(uint32, 10, 12, 28)
outputXshRr(uint64, 18, 27, 59)

# rxs m xs
template outputRxsMXs(stateTyp: typedesc, consts: varargs[uint64]) =
  proc output[S: PcgStateVariant](r: PcgRand[stateTyp, S, RxsMXs]): stateTyp =
    let word = ((r.state shr ((r.state shr consts[0]) + consts[1])) xor r.state) * consts[2]
    result = stateTyp((word shr consts[3]) xor word)
outputRxsMXs(uint8, 6, 2, 217, 6)
outputRxsMXs(uint16, 13, 3, 62169, 11)
outputRxsMXs(uint32, 28, 4, 277803737, 22)
outputRxsMXs(uint64, 59, 5, 12605985483714917081'u64, 43)

# rxs m
template outputRxsM(stateTyp: typedesc, consts: varargs[uint64]) =
  proc output[S: PcgStateVariant](r: PcgRand[stateTyp, S, RxsM]): smaller(stateTyp) =
    result = smaller(stateTyp)((((r.state shr ((r.state shr consts[0]) + consts[1])) xor r.state) * consts[2]) shr sizeof(smaller(stateTyp))*8)
outputRxsM(uint16, 13, 3, 62169)
outputRxsM(uint32, 28, 4, 277803737)
outputRxsM(uint64, 59, 5, 12605985483714917081'u64)

# xsl rr
template outputXslRr(stateTyp: typedesc, consts: varargs[uint32]) =
  proc output[S: PcgStateVariant](r: PcgRand[stateTyp, S, XslRr]): smaller(stateTyp) =
    result = rotr((smaller(stateTyp)(r.state shr (sizeof(smaller(stateTyp))*8))) xor smaller(stateTyp)(r.state), r.state shr consts[0])
outputXslRr(uint64, 59)

# xsl rr rr
template outputXslRrRr(stateTyp: typedesc, consts: varargs[uint32]) =
  proc output[S: PcgStateVariant](r: PcgRand[stateTyp, S, XslRrRr]): stateTyp =
    let
      rot1 = uint32(r.state shr consts[0])
      high = smaller(stateTyp)(r.state shr consts[1])
      low = smaller(stateTyp)(r.state)
      xored = high xor low
      newlow = rotr(xored, rot1)
      newhigh = rotr(high, newlow and consts[1]-1)
    result = ((stateTyp newhigh) shl consts[1]) or newlow
outputXslRrRr(uint64, 59, 32)

# -- lcg multi advance/step

template defaultMultiplier(t: typedesc): t =
  when t == uint8:
    141
  elif t == uint16:
    12829
  elif t == uint32:
    747796405
  elif t == uint64:
    6364136223846793005

template defaultIncrement(t: typedesc): t =
  when t == uint8:
    77
  elif t == uint16:
    47989
  elif t == uint32:
    2891336453
  elif t == uint64:
    1442695040888963407

proc advanceLcg[T: SomeUnsignedInt](state, delta, curMult, curPlus: T): T =
  var
    curMult = curMult
    curPlus = curPlus
    accMult: T = 1
    accPlus: T = 0
  while delta > 0: 
    if delta and 1 != 0: 
      accMult *= curMult
      accPlus = accPlus * curMult + curPlus
    curPlus = (curMult + 1) * curPlus
    curMult *= curMult
    delta = delta div 2
  result = accMult * state + accPlus

# --- lcg advance/step

proc step[T: SomeUnsignedInt, G: PcgGeneratorVariant](r: var PcgRand[T, OneSeq, G]) =
  r.state = r.state * defaultMultiplier(T) + defaultIncrement(T)

proc advance[T: SomeUnsignedInt, G: PcgGeneratorVariant](r: var PcgRand[T, OneSeq, G], delta: T) =
  r.state = advanceLcg(r.state, delta, defaultMultiplier(T), defaultIncrement(T))

proc step[T: SomeUnsignedInt, G: PcgGeneratorVariant](r: var PcgRand[T, Mcg, G]) =
  r.state = r.state * defaultMultiplier(T)

proc advance[T: SomeUnsignedInt, G: PcgGeneratorVariant](r: var PcgRand[T, Mcg, G], delta: T) =
  r.state = advanceLcg(r.state, delta, defaultMultiplier(T), 0)

proc step[T: SomeUnsignedInt, G: PcgGeneratorVariant](r: var PcgRand[T, Unique, G]) =
  r.state = r.state * defaultMultiplier(T) + (r.state or 1)

proc advance[T: SomeUnsignedInt, G: PcgGeneratorVariant](r: var PcgRand[T, Unique, G], delta: T) =
  r.state = advanceLcg(r.state, delta, defaultMultiplier(T), (r.state or 1))

proc step[T: SomeUnsignedInt, G: PcgGeneratorVariant](r: var PcgRand[T, SetSeq, G]) =
  r.state = r.state * defaultMultiplier(T) + r.incr

proc advance[T: SomeUnsignedInt, G: PcgGeneratorVariant](r: var PcgRand[T, SetSeq, G], delta: T) =
  r.state = advanceLcg(r.state, delta, defaultMultiplier(T), r.incr)

# --- init/seed

proc initPcgRand*[T: SomeUnsignedInt, S: PcgStateVariant, G: PcgGeneratorVariant](initstate: T): PcgRand[T, S, G] =
  when S == OneSeq:
    result.state = 0
    step(result)
    result.state += initstate
    step(result)
  else S == Mcg:
    result.state = initstate or 1
  else S == Unique:
    result.state = 0
    step(result)
    result.state += initstate
    step(result)
  else S == SetSeq:
    result.state = 0
    result.incr = (initseq shl 1) or 1
    step(result)
    result.state += initstate
    step(result)

# --- generators

proc next*(r: var PcgRand[SomeUnsignedInt, PcgStateVariant, PcgGeneratorVariant]): auto =
  result = r.state.output()
  step(r)

pkgRandomProcGen(PcgRand[uint64, PcgStateVariant, PcgEqualReturnGenerator], uint64)
pkgRandomProcGen(PcgRand[uint32, PcgStateVariant, PcgEqualReturnGenerator], uint32)
pkgRandomProcGen(PcgRand[uint8, PcgStateVariant, PcgEqualReturnGenerator], uint8)

pkgRandomProcGen(PcgRand[uint64, PcgStateVariant, PcgSmallerReturnGenerator], uint32)
pkgRandomProcGen(PcgRand[uint16, PcgStateVariant, PcgSmallerReturnGenerator], uint8)

