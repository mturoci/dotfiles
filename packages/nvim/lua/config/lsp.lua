local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- helm-ls only activates on the `helm`/`gotmpl` filetypes, but Helm chart
-- templates are detected as plain yaml by default. Fix detection so the
-- server (and template-aware highlighting) kicks in.
vim.filetype.add({
  pattern = {
    [".*/templates/.*%.ya?ml"] = "helm",
    [".*/templates/.*%.tpl"] = "helm",
  },
})

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
    end,
    ["helm_ls"] = function()
      require("lspconfig").helm_ls.setup({
        capabilities = capabilities,
        settings = {
          ["helm-ls"] = {
            yamllint = { enabled = true },
            valuesFiles = { "values.yaml" },
          },
        },
      })
    end,
    ["tsgo"] = {
      cmd = { "tsgo", "--lsp", "--stdio" },
      filetypes = {
        "javascript",
        "javascriptreact",
        "javascript.jsx",
        "typescript",
        "typescriptreact",
        "typescript.tsx",
      },
      root_markers = {
        "tsconfig.json",
        "jsconfig.json",
        "package.json",
        ".git",
        "tsconfig.base.json",
      },
      enabled = true,
    },
  }
})
