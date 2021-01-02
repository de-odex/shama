
type
  Plus* = distinct void
  PlusPlus* = distinct void
  StarStar* = distinct void
  XorshiftLikeGeneratorVariant* = Plus or PlusPlus or StarStar
  # my lord, this is long. i apologize heavily. suggestions welcome maybe.

proc rotl*(x, k: uint64): uint64 =
  result = (x shl k) or (x shr (64u64 - k))

