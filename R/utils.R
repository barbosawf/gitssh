# Small internal null-coalescing helper (kept local so the package has no
# hard dependency on rlang, and works on R < 4.4 where base lacks `%||%`).
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
