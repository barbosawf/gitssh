walk_L <- function(x, f) {
  if (is.character(x) && identical(names(x), .tips_langs)) {
    f(x)
  } else if (is.list(x)) {
    invisible(lapply(x, walk_L, f = f))
  }
}

test_that("every translated string has all three languages, non-empty", {
  content <- .git_tips_content()
  n <- 0
  walk_L(content, function(x) {
    n <<- n + 1
    expect_true(all(nzchar(x)), info = paste(x, collapse = " | "))
  })
  expect_gt(n, 50)
})

test_that("every exported function is documented in the cheat sheet", {
  content <- .git_tips_content()
  text <- paste(unlist(lapply(content$reference, function(g) {
    vapply(g$items, `[[`, character(1), "fn")
  })), collapse = " ")
  exported <- setdiff(getNamespaceExports("gitssh"), "git_tips")
  missing <- exported[!vapply(exported, grepl, logical(1), x = text, fixed = TRUE)]
  expect_equal(missing, character(0))
})

test_that("the HTML page has the three languages and the switch buttons", {
  path <- git_tips(open = FALSE, lang = "en")
  html <- paste(readLines(path, encoding = "UTF-8"), collapse = "\n")
  expect_match(html, 'data-lang="en"', fixed = TRUE)
  for (l in c("pt-BR", "en", "es")) {
    expect_match(html, sprintf('data-set="%s"', l), fixed = TRUE)
    expect_match(html, sprintf('<span data-l="%s">', l), fixed = TRUE)
  }
  expect_match(html, "Git / SSH cheat sheet", fixed = TRUE)
  expect_match(html, "Guia rápido de Git / SSH", fixed = TRUE)
  expect_false(grepl("@@", html, fixed = TRUE))
})

test_that("console mode prints the chosen language", {
  expect_output(git_tips(console = TRUE, lang = "es"), "Guía rápida de Git / SSH")
  expect_output(git_tips(console = TRUE, lang = "en"), "Cloning someone else's")
  expect_output(git_tips(console = TRUE), "Clonar um repositório de terceiros")
  expect_error(git_tips(lang = "fr"))
})
