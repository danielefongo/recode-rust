if os.getenv("TEST_COV") then
  require("luacov")
end

local M = {}
local needed_plugins = {
  "nvim-lua/plenary.nvim",
  "nvim-treesitter/nvim-treesitter",
  "williamboman/mason.nvim",
  "danielefongo/recode.nvim",
}

function M.root(root)
  local f = debug.getinfo(1, "S").source:sub(2)
  return vim.fn.fnamemodify(f, ":p:h:h") .. "/" .. (root or "")
end

function M.load(plugin)
  local name = plugin:match(".*/(.*)")
  local package_root = M.root(".tests/site/pack/deps/start/")
  if not vim.loop.fs_stat(package_root .. name) then
    print("Installing " .. plugin)
    vim.fn.mkdir(package_root, "p")
    vim.fn.system({
      "git",
      "clone",
      "--depth=1",
      "https://github.com/" .. plugin .. ".git",
      package_root .. "/" .. name,
    })
  end
end

function M.prepare_lsp()
  if not vim.loop.fs_stat(vim.env.XDG_DATA_HOME .. "/nvim/mason/bin/rust-analyzer") then
    require("mason").setup({})
    vim.cmd([[MasonInstall rust-analyzer]])
  end

  local function start_lsp()
    return vim.lsp.start({
      name = "rust-analyzer",
      autostart = true,
      cmd = { vim.env.XDG_DATA_HOME .. "/nvim/mason/bin/rust-analyzer" },
      root_dir = vim.fn.getcwd() .. "/lua/tests/example",
      settings = {},
    })
  end

  local rust_lsp_client = nil
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "rust",
    callback = function(data)
      if not rust_lsp_client then
        rust_lsp_client = start_lsp()
      end
      vim.lsp.buf_attach_client(data.buf, rust_lsp_client)
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      if rust_lsp_client then
        vim.lsp.stop_client(rust_lsp_client, true)
      end
    end,
  })
end

function M.setup()
  vim.cmd([[set runtimepath=$VIMRUNTIME]])
  vim.opt.runtimepath:append(M.root())
  vim.opt.runtimepath:append("./")
  vim.opt.packpath = { M.root(".tests/site") }
  vim.env.XDG_CONFIG_HOME = M.root(".tests/config")
  -- vim.env.XDG_DATA_HOME = M.root(".tests/data")
  vim.env.XDG_STATE_HOME = M.root(".tests/state")
  vim.env.XDG_CACHE_HOME = M.root(".tests/cache")

  for _, plugin in pairs(needed_plugins) do
    M.load(plugin)
  end

  M.prepare_lsp()

  print("Setup complete...\n")
end

M.setup()
