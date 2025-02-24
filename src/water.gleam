//// Compiles a Markdown variant into innerHTML for IYLC

import argv
import gleam/list
import simplifile

import water/util

pub fn main() {
  argv.load().arguments
  |> list.filter_map(fn(x) { simplifile.read(from: x) })
  |> list.map(util.process_file)
}
