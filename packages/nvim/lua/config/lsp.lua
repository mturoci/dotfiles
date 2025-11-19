local capabilities = require("cmp_nvim_lsp").default_capabilities()

vim.diagnostic.config({ virtual_text = true, })

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
