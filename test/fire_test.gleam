import gleeunit
import gleeunit/should

import gleam/int
import gleam/io
import gleam/list
import gleam/result
import simplifile

import fire/util

pub fn main() {
  gleeunit.main()
}

fn count_down(acc, n) {
  list.append(acc, [n])
  |> fn(x) {
    case n {
      0 -> x
      _ -> count_down(x, n - 1)
    }
  }
}

pub fn integration_test() {
  count_down([], 3)
  |> list.map(fn(x) {
    { "cases/" <> int.to_string(x) <> ".md" }
    |> simplifile.read()
    |> result.unwrap("couldn't open test")
    |> util.process_file()
    |> should.equal(
      { "cases/" <> int.to_string(x) <> ".html" }
      |> simplifile.read()
      |> result.unwrap("couldn't open truth"),
    )
  })
}
