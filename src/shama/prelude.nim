
# nim-random compat.; import pkg/random/common yourself tho
# seriously, i hate the fact that i need to put the type name in the proc name
template pkgRandomProcGen*(rTyp: typedesc, retTyp: typedesc) =
  proc `random retTyp`*(r: var rTyp): retTyp =
    r.next()

