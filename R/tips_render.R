# Internal engine behind git_tips(): renders a trilingual (pt-BR / en / es)
# cheat sheet either as a self-contained HTML page with language buttons, or
# as plain text in the console.
#
# A "content" object is a list with:
#   pkg        package name (used in titles / file name)
#   ui         named list of L() strings: title, subtitle, workflows,
#              reference, footer, console_hint
#   workflows  list of list(title = L(), note = L(), steps = list(step(...)))
#   reference  list of list(group = L(), items = list(list(fn = "", desc = L())))

.tips_langs <- c("pt-BR", "en", "es")
.tips_lang_labels <- c("pt-BR" = "Portugu\u00eas", "en" = "English", "es" = "Espa\u00f1ol")

# One translated string: L(pt, en, es).
L <- function(pt, en, es) {
  stats::setNames(c(pt, en, es), .tips_langs)
}

# One workflow step: some code, plus an optional translated comment.
step <- function(code, cmt = NULL) {
  list(code = code, cmt = cmt)
}

.tips_esc <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x
}

# A translated string as three sibling <span data-l="..."> elements; CSS hides
# all but the active language.
.tips_spans <- function(x) {
  paste0(
    vapply(.tips_langs, function(l) {
      sprintf('<span data-l="%s">%s</span>', l, .tips_esc(x[[l]]))
    }, character(1)),
    collapse = ""
  )
}

.tips_html <- function(content, lang) {
  ui <- content$ui

  workflow_html <- vapply(content$workflows, function(w) {
    steps_html <- vapply(w$steps, function(s) {
      cmt <- if (is.null(s$cmt)) "" else sprintf(' <code class="cmt"># %s</code>', .tips_spans(s$cmt))
      is_comment_only <- grepl("^\\s*#", s$code)
      cls <- if (is_comment_only) ' class="cmt"' else ""
      sprintf("<li><code%s>%s</code>%s</li>", cls, .tips_esc(s$code), cmt)
    }, character(1))
    sprintf(
      '<div class="card">\n  <h3>%s</h3>\n  <p class="note">%s</p>\n  <ol>\n    %s\n  </ol>\n</div>',
      .tips_spans(w$title), .tips_spans(w$note), paste(steps_html, collapse = "\n    ")
    )
  }, character(1))

  reference_html <- vapply(content$reference, function(g) {
    rows <- vapply(g$items, function(it) {
      sprintf("<tr><td><code>%s</code></td><td>%s</td></tr>", .tips_esc(it$fn), .tips_spans(it$desc))
    }, character(1))
    sprintf(
      '<h3>%s</h3>\n<table>\n  <tbody>\n    %s\n  </tbody>\n</table>',
      .tips_spans(g$group), paste(rows, collapse = "\n    ")
    )
  }, character(1))

  buttons <- paste(
    vapply(.tips_langs, function(l) {
      sprintf('<button type="button" data-set="%s" aria-pressed="%s">%s</button>',
              l, tolower(identical(l, lang)), .tips_lang_labels[[l]])
    }, character(1)),
    collapse = "\n      "
  )

  subtitle <- .tips_spans(L(
    sprintf(ui$subtitle[["pt-BR"]], format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
    sprintf(ui$subtitle[["en"]],    format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
    sprintf(ui$subtitle[["es"]],    format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
  ))

  template <- '<!DOCTYPE html>
<html lang="@@LANG@@" data-lang="@@LANG@@">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>@@PKG@@ :: cheat sheet</title>
<style>
  :root {
    color-scheme: light dark;
    --bg: #f7f7f8; --fg: #1c1c1e; --card: #ffffff; --border: #e0e0e3;
    --accent: #2f6fed; --accent-fg: #ffffff; --code-bg: #eef1f6; --muted: #6b6b70;
  }
  @media (prefers-color-scheme: dark) {
    :root { --bg: #16171a; --fg: #eaeaec; --card: #202126; --border: #33343a;
            --accent: #6ea2ff; --accent-fg: #101114; --code-bg: #292a30; --muted: #a0a0a6; }
  }
  * { box-sizing: border-box; }
  body {
    margin: 0; padding: 2rem 1.25rem 4rem; background: var(--bg); color: var(--fg);
    font-family: -apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    line-height: 1.5;
  }
  .wrap { max-width: 880px; margin: 0 auto; }
  .top { display: flex; flex-wrap: wrap; align-items: flex-start; justify-content: space-between; gap: 1rem; }
  h1 { font-size: 1.6rem; margin: 0 0 0.25rem; }
  .subtitle { color: var(--muted); margin-top: 0; margin-bottom: 2rem; }
  .langs { display: inline-flex; border: 1px solid var(--border); border-radius: 8px; overflow: hidden; }
  .langs button {
    font: inherit; font-size: 0.85rem; padding: 0.35rem 0.8rem; cursor: pointer;
    border: 0; border-right: 1px solid var(--border); background: var(--card); color: var(--fg);
  }
  .langs button:last-child { border-right: 0; }
  .langs button[aria-pressed="true"] { background: var(--accent); color: var(--accent-fg); font-weight: 600; }
  h2 { font-size: 1.15rem; border-bottom: 1px solid var(--border); padding-bottom: 0.4rem; margin-top: 2.5rem; }
  .card { background: var(--card); border: 1px solid var(--border); border-radius: 10px; padding: 1rem 1.25rem; margin: 1rem 0; }
  .card h3 { margin-top: 0; margin-bottom: 0.3rem; font-size: 1.02rem; }
  .card .note { color: var(--muted); margin-top: 0; margin-bottom: 0.75rem; font-size: 0.92rem; }
  .card ol { margin: 0; padding-left: 1.25rem; }
  .card li { margin: 0.15rem 0; }
  code {
    background: var(--code-bg); border-radius: 4px; padding: 0.1rem 0.35rem;
    font-family: ui-monospace, SFMono-Regular, Consolas, "Courier New", monospace; font-size: 0.88rem;
  }
  code.cmt { background: transparent; color: var(--muted); font-style: italic; }
  table { width: 100%; border-collapse: collapse; margin: 0.5rem 0 1.5rem; }
  td { padding: 0.4rem 0.6rem; border-bottom: 1px solid var(--border); vertical-align: top; }
  td:first-child { width: 38%; word-break: break-word; }
  footer { color: var(--muted); font-size: 0.85rem; margin-top: 3rem; text-align: center; }
  /* Show only the active language. */
  html[data-lang="pt-BR"] [data-l]:not([data-l="pt-BR"]),
  html[data-lang="en"]    [data-l]:not([data-l="en"]),
  html[data-lang="es"]    [data-l]:not([data-l="es"]) { display: none; }
  @media (max-width: 600px) { td:first-child { width: auto; } }
</style>
</head>
<body>
<div class="wrap">
  <div class="top">
    <div>
      <h1>@@PKG@@ :: @@TITLE@@</h1>
      <p class="subtitle">@@SUBTITLE@@</p>
    </div>
    <div class="langs" role="group" aria-label="Language">
      @@BUTTONS@@
    </div>
  </div>

  <h2>@@H_WORKFLOWS@@</h2>
  @@WORKFLOWS@@

  <h2>@@H_REFERENCE@@</h2>
  @@REFERENCE@@

  <footer>@@FOOTER@@</footer>
</div>
<script>
  (function () {
    var root = document.documentElement;
    var buttons = document.querySelectorAll(".langs button");
    function setLang(l) {
      root.setAttribute("data-lang", l);
      root.setAttribute("lang", l);
      buttons.forEach(function (b) {
        b.setAttribute("aria-pressed", String(b.getAttribute("data-set") === l));
      });
    }
    buttons.forEach(function (b) {
      b.addEventListener("click", function () { setLang(b.getAttribute("data-set")); });
    });
  })();
</script>
</body>
</html>
'

  fills <- list(
    LANG        = lang,
    PKG         = content$pkg,
    TITLE       = .tips_spans(ui$title),
    SUBTITLE    = subtitle,
    BUTTONS     = buttons,
    H_WORKFLOWS = .tips_spans(ui$workflows),
    WORKFLOWS   = paste(workflow_html, collapse = "\n\n  "),
    H_REFERENCE = .tips_spans(ui$reference),
    REFERENCE   = paste(reference_html, collapse = "\n\n  "),
    FOOTER      = .tips_spans(ui$footer)
  )
  out <- template
  for (k in names(fills)) {
    out <- gsub(sprintf("@@%s@@", k), fills[[k]], out, fixed = TRUE)
  }
  out
}

.tips_console <- function(content, lang) {
  ui <- content$ui
  rule <- strrep("=", 72)
  thin <- strrep("-", 72)
  out <- c(rule, sprintf("%s :: %s", content$pkg, ui$title[[lang]]), rule, "",
           ui$console_hint[[lang]], "")

  out <- c(out, toupper(ui$workflows[[lang]]), thin)
  for (w in content$workflows) {
    out <- c(out, "", sprintf("* %s", w$title[[lang]]), sprintf("  %s", w$note[[lang]]))
    for (s in w$steps) {
      cmt <- if (is.null(s$cmt)) "" else sprintf("  # %s", s$cmt[[lang]])
      out <- c(out, sprintf("    %s%s", s$code, cmt))
    }
  }

  out <- c(out, "", "", toupper(ui$reference[[lang]]), thin)
  for (g in content$reference) {
    out <- c(out, "", sprintf("[%s]", g$group[[lang]]))
    for (it in g$items) {
      out <- c(out, sprintf("  %s", it$fn), sprintf("      %s", it$desc[[lang]]))
    }
  }
  c(out, "")
}

# Shared implementation of the *_tips() functions.
.show_tips <- function(content, lang, open, console, file_stub) {
  if (isTRUE(console)) {
    writeLines(.tips_console(content, lang))
    return(invisible(NULL))
  }

  html <- .tips_html(content, lang)
  path <- file.path(tempdir(), paste0(file_stub, ".html"))
  con <- file(path, open = "w", encoding = "UTF-8")
  on.exit(close(con))
  writeLines(html, con, useBytes = TRUE)
  close(con)
  on.exit()

  if (isTRUE(open)) {
    utils::browseURL(path)
  }

  invisible(path)
}
