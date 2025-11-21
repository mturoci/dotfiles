local capabilities = require("cmp_nvim_lsp").default_capabilities()

vim.diagnostic.config({
  virtual_text = true,
  float = { border = "rounded" }
})

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
  vim.lsp.handlers.hover,
  { border = "rounded" }
)

vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
  vim.lsp.handlers.signature_help,
  { border = "rounded" }
)

require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = { "lua_ls", "gopls", "pyright" },
  automatic_installation = true,
  handlers = {
    function(server_name)
      require("lspconfig")[server_name].setup { capabilities = capabilities }
    end,
    ["lua_ls"] = function()
      require("lspconfig").lua_ls.setup({ capabilities = capabilities })
    end
  }
})
