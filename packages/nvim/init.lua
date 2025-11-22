local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable releas
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("config.options")
require("lazy").setup("config.plugins", { rocks = { enabled = false } }) --  https://github.com/natecraddock/telescope-zf-native.nvim/issues/21
require("config.lsp")
require("config.appearance")
require("config.statusline")
require("config.keymaps")

-- Race condition on ssh connections. For some reason, this needs to be after OSC52 has completed registration, not before.
local utils = require 'config.utils'
utils.setTimeout(500, function() vim.opt.clipboard = "unnamed,unnamedplus" end)

-- Reload all open buffers even when changed externally.
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI' }, {
  pattern = '*',
  callback = function()
    if vim.fn.mode():match('[crt!]') or vim.fn.getcmdwintype() ~= '' then
      return
    end

    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_option(buf, 'buftype') == '' then
        vim.api.nvim_buf_call(buf, function() vim.cmd('checktime') end)
      end
    end
  end,
})
