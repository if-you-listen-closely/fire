//// Markdown Parser Utilities

import gleam/list
import gleam/string

import gleam/io

type Matcher {
  Matcher(
    str: String,
    current_pol: Policy,
    next_pol: Policy,
    head: Int,
    tail: Int,
  )
}

type Policy {
  Policy(indicator: String, repeats: Int, replacement: String, closes: Bool)
}

pub fn process_file(file_content: String) -> String {
  let st =
    file_content
    |> string.replace(each: "  \n", with: "<br>")
    |> tokenize()
    |> list.map(process_line)
    |> list.map(tag)
    |> string.concat()

  st
}

fn tokenize(strtr: String) -> List(String) {
  string.split(strtr, "\n")
  |> list.filter(fn(x) { !string.is_empty(x) })
}

fn tag(line: String) -> String {
  case line {
    "# " <> header -> "<h1>" <> header <> "</h1>"
    "## " <> header -> "<h2>" <> header <> "</h2>"
    "### " <> header -> "<h3>" <> header <> "</h3>"
    "#### " <> header -> "<h4>" <> header <> "</h4>"
    "##### " <> header -> "<h5>" <> header <> "</h5>"
    "###### " <> header -> "<h6>" <> header <> "</h6>"
    _ -> "<p>" <> line <> "</p>"
  }
}

fn process_line(line: String) -> String {
  string.split(line, "")
  // Escape Special Characters
  |> list.map(fn(x) {
    case x {
      "<" -> "&lt;"
      ">" -> "&gt;"
      "&" -> "&amp;"
      _ -> x
    }
  })
  |> string.join("")
  |> text_decorate("*", 2, "b")
  |> text_decorate("_", 1, "i")
  |> text_decorate("~", 2, "s")
}

fn text_decorate(
  str: String,
  indicator: String,
  repeats: Int,
  replacement: String,
) -> String {
  let opener = Policy(indicator, repeats, replacement, False)
  let closer = Policy(indicator, repeats, "/" <> replacement, True)

  case
    string.slice(str, 0, repeats) == string.repeat(indicator, repeats)
    && string.slice(str, repeats, 1) != indicator
  {
    True -> Matcher(str, closer, opener, 0, -1)
    _ -> Matcher(str, opener, closer, 0, 0)
  }
  |> decorate_helper()
}

fn decorate_helper(state: Matcher) -> String {
  case state.head + state.current_pol.repeats >= string.length(state.str) {
    True -> state.str
    False ->
      case
        check_tag(
          string.slice(state.str, state.head, state.current_pol.repeats + 2),
          state.current_pol,
        )
      {
        True ->
          case state.current_pol.closes {
            True ->
              tag_insert(state.str, state.head + 1, state.current_pol)
              |> tag_insert(state.tail + 1, state.next_pol)
            False -> state.str
          }
          |> fn(x) {
            Matcher(
              x,
              state.next_pol,
              state.current_pol,
              state.head + 1 + state.current_pol.repeats,
              state.head,
            )
          }
        False ->
          Matcher(
            state.str,
            state.current_pol,
            state.next_pol,
            state.head + 1,
            state.tail,
          )
      }
      |> decorate_helper()
  }
}

fn check_tag(x: String, pol: Policy) -> Bool {
  string.slice(x, 0, 1) != pol.indicator
  && string.slice(x, 1, pol.repeats)
  == string.repeat(pol.indicator, pol.repeats)
  && string.slice(x, pol.repeats + 1, 1) != pol.indicator
  && case pol.closes {
    True -> string.slice(x, 0, 1)
    False -> string.slice(x, pol.repeats + 1, 1)
  }
  != " "
}

fn tag_insert(x: String, idx: Int, pol: Policy) -> String {
  string.slice(x, 0, idx)
  <> "<"
  <> pol.replacement
  <> ">"
  <> string.slice(x, idx + pol.repeats, string.length(x))
}
