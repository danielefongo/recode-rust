local helpers = require("tests.helpers")
local Range = require("recode.range")
local RustRename = require("recode-rust.refactors.rename")

describe("rename", function()
  helpers.setup()

  local buffers = {}

  after_each(function()
    helpers.unregister_buffers(buffers)
  end)

  it("variable", function()
    local main = helpers.register_buffer(
      buffers,
      "lua/tests/example/src/code.rs",
      [[
pub fn my_function(param1: i32, param2: i32) {
  let param2 = param2 + 1;
}]]
    )

    local actions = helpers.with_lsp(RustRename.apply, main, Range.new(1, 15, 1, 16), { name = "renamed" })

    helpers.apply_actions(buffers, actions)

    assert.are.same(
      [[
pub fn my_function(param1: i32, renamed: i32) {
  let param2 = renamed + 1;
}]],
      helpers.buf_read(main)
    )
  end)

  it("function", function()
    local main = helpers.register_buffer(
      buffers,
      "lua/tests/example/src/code.rs",
      [[
pub fn my_function(param1: i32, param2: i32) {
  let param2 = param2 + 1;
}]]
    )

    local actions = helpers.with_lsp(RustRename.apply, main, Range.new(0, 7, 0, 7), { name = "renamed" })

    helpers.apply_actions(buffers, actions)

    assert.are.same(
      [[
pub fn renamed(param1: i32, param2: i32) {
  let param2 = param2 + 1;
}]],
      helpers.buf_read(main)
    )
  end)

  it("field", function()
    local main = helpers.register_buffer(
      buffers,
      "lua/tests/example/src/code.rs",
      [[
struct X { field: i32 }
pub fn my_function(x: X) {
  let value = x.field;
}]]
    )

    local actions = helpers.with_lsp(RustRename.apply, main, Range.new(2, 16, 2, 16), { name = "renamed" })

    helpers.apply_actions(buffers, actions)

    assert.are.same(
      [[
struct X { renamed: i32 }
pub fn my_function(x: X) {
  let value = x.renamed;
}]],
      helpers.buf_read(main)
    )
  end)

  it("variant", function()
    local main = helpers.register_buffer(
      buffers,
      "lua/tests/example/src/code.rs",
      [[
enum X { One(String) }
pub fn my_function(x: X) {
  if let X::One(_) = x {
    ;
  }
}]]
    )

    local actions = helpers.with_lsp(RustRename.apply, main, Range.new(2, 12, 2, 12), { name = "Renamed" })

    helpers.apply_actions(buffers, actions)

    assert.are.same(
      [[
enum X { Renamed(String) }
pub fn my_function(x: X) {
  if let X::Renamed(_) = x {
    ;
  }
}]],
      helpers.buf_read(main)
    )
  end)

  it("across files", function()
    local main = helpers.register_buffer(
      buffers,
      "lua/tests/example/src/code.rs",
      [[
pub fn my_function(param1: i32, param2: i32) {
  let param2 = param2 + 1;
}]]
    )

    local user = helpers.register_buffer(
      buffers,
      "lua/tests/example/src/user.rs",
      [[
use crate::code;
pub fn main() {
  let _ = code::my_function(1, 2);
}]]
    )

    local actions = helpers.with_lsp(RustRename.apply, main, Range.new(0, 7, 0, 7), { name = "renamed" })

    helpers.apply_actions(buffers, actions)

    assert.are.same(
      [[
pub fn renamed(param1: i32, param2: i32) {
  let param2 = param2 + 1;
}]],
      helpers.buf_read(main)
    )

    assert.are.same(
      [[
use crate::code;
pub fn main() {
  let _ = code::renamed(1, 2);
}]],
      helpers.buf_read(user)
    )
  end)
end)
