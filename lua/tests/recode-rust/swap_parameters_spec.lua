local helpers = require("tests.helpers")
local Range = require("recode.range")
local RustSwapParameter = require("recode-rust.refactors.swap_parameter")

describe("swap parameters", function()
  helpers.setup()

  local buffers = {}

  after_each(function()
    helpers.unregister_buffers(buffers)
  end)

  it("simple", function()
    local main = helpers.register_buffer(
      buffers,
      "lua/tests/example/src/code.rs",
      [[
pub fn my_function(param1: &str, param2: i32) {
  let param2 = param2 + 1;
}
pub fn caller() {
  my_function("hi", 2);
}
]]
    )

    local actions = helpers.with_lsp(RustSwapParameter.apply, main, Range.new(1, 0, 1, 0), { from = 1, to = 2 })

    helpers.apply_actions(buffers, actions)

    assert.are.same(
      [[
pub fn my_function(param2: i32, param1: &str) {
  let param2 = param2 + 1;
}
pub fn caller() {
  my_function(2, "hi");
}
]],
      helpers.buf_read(main)
    )
  end)

  it("many params", function()
    local main = helpers.register_buffer(
      buffers,
      "lua/tests/example/src/code.rs",
      [[
pub fn my_function(param1: &str, param2: i32, param3: Box<String>) {
  let param2 = param2 + 1;
}
pub fn caller() {
  my_function("hi", 2, Box::new("hi".to_string()));
}
]]
    )

    local actions = helpers.with_lsp(RustSwapParameter.apply, main, Range.new(1, 0, 1, 0), { from = 1, to = 3 })

    helpers.apply_actions(buffers, actions)

    assert.are.same(
      [[
pub fn my_function(param3: Box<String>, param2: i32, param1: &str) {
  let param2 = param2 + 1;
}
pub fn caller() {
  my_function(Box::new("hi".to_string()), 2, "hi");
}
]],
      helpers.buf_read(main)
    )
  end)

  it("across files", function()
    local main = helpers.register_buffer(
      buffers,
      "lua/tests/example/src/code.rs",
      [[
pub fn my_function(param1: &str, param2: i32) {
  let param2 = param2 + 1;
}]]
    )

    local lib = helpers.register_buffer(
      buffers,
      "lua/tests/example/src/user.rs",
      [[
use crate::code;
pub fn main() {
  let _ = code::my_function("hi", 2);
}]]
    )

    local actions = helpers.with_lsp(RustSwapParameter.apply, main, Range.new(1, 0, 1, 0), { from = 1, to = 2 })

    helpers.apply_actions(buffers, actions)

    assert.are.same(
      [[
pub fn my_function(param2: i32, param1: &str) {
  let param2 = param2 + 1;
}]],
      helpers.buf_read(main)
    )

    assert.are.same(
      [[
use crate::code;
pub fn main() {
  let _ = code::my_function(2, "hi");
}]],
      helpers.buf_read(lib)
    )
  end)

  it("skips self", function()
    local main = helpers.register_buffer(
      buffers,
      "lua/tests/example/src/code.rs",
      [[
struct X;
impl X {
  pub fn my_function(&self, param1: &str, param2: i32) {
    let param2 = param2 + 1;
  }
}
pub fn caller() {
  X.my_function("hi", 2);
}
]]
    )

    local actions = helpers.with_lsp(RustSwapParameter.apply, main, Range.new(3, 0, 3, 0), { from = 1, to = 2 })

    helpers.apply_actions(buffers, actions)

    assert.are.same(
      [[
struct X;
impl X {
  pub fn my_function(&self, param2: i32, param1: &str) {
    let param2 = param2 + 1;
  }
}
pub fn caller() {
  X.my_function(2, "hi");
}
]],
      helpers.buf_read(main)
    )
  end)
end)
