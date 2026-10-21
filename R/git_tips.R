#' Cheat Sheet for This Package's Git / SSH Helpers (pt-BR, English, Spanish)
#'
#' @description
#' Shows every \code{git_*} / SSH-related helper in this package, organized
#' around \emph{workflows} -- common situations (first-time setup, cloning
#' your own or someone else's repository, daily pull/push, an HTTPS remote
#' that needs converting, stashing work in progress, recovering from a forced
#' reset/push) -- plus a reference table with what each function does.
#'
#' By default the cheat sheet is rendered as a self-contained HTML page and
#' opened in the system browser, with buttons at the top right to switch
#' between \strong{Português (pt-BR)}, \strong{English} and
#' \strong{Español} without reloading. Alternatively, with
#' \code{console = TRUE} the same content is printed as plain text in the R
#' console, in the language given by \code{lang}.
#'
#' @param open Logical. If \code{TRUE} (default), opens the HTML page in the
#'   system browser with \code{\link[utils]{browseURL}}. Set to \code{FALSE}
#'   to only write the file (e.g. in non-interactive sessions). Ignored when
#'   \code{console = TRUE}.
#' @param lang Character. Initial language: \code{"pt-BR"} (default),
#'   \code{"en"} or \code{"es"}. In the HTML page it can be changed at any
#'   time with the buttons.
#' @param console Logical. If \code{TRUE}, prints the cheat sheet in the
#'   console (in \code{lang}) instead of writing/opening an HTML page.
#'   Default \code{FALSE}.
#' @return Invisibly returns the path to the generated HTML file, or
#'   \code{NULL} when \code{console = TRUE}.
#' @export
#'
#' @examples
#' \dontrun{
#' git_tips()                             # HTML page, starts in pt-BR
#' git_tips(lang = "en")                  # HTML page, starts in English
#' git_tips(lang = "es", console = TRUE)  # plain text in the console
#' }
git_tips <- function(open = TRUE, lang = c("pt-BR", "en", "es"), console = FALSE) {
  lang <- match.arg(lang)
  .show_tips(.git_tips_content(), lang = lang, open = open, console = console,
             file_stub = "gitssh_git_tips")
}
